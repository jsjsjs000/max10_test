module spi_client #(
	parameter integer CLK_FREQ_HZ     = 50000000,
	parameter integer SPI_TIMEOUT_US  = 1000,
	parameter integer LED_TIME_MS     = 10,

	parameter integer RW_REG_COUNT    = 32,
	parameter integer RO_BASE_ADDR    = 8'h80,
	parameter integer RO_REG_COUNT    = 32,

	// 0 = LED active high
	// 1 = LED active low
	parameter integer LED_ACTIVE_LOW  = 0
)(
	input  wire                         clk,
	input  wire                         rst_n,

	// SPI-like interface from M7
	// Mode 0, MSB first
	input  wire                         m7_clk,       // SCK
	input  wire                         m7_tx,        // MOSI
	output reg                          max10_tx,     // MISO

	// Registers visible to logic inside MAX10
	output wire [(RW_REG_COUNT*8)-1:0] rw_regs_out,
	input  wire [(RO_REG_COUNT*8)-1:0] ro_regs_in,

	output wire                         led
);

	// ============================================================
	// Protocol
	//
	// Request:
	//
	//   A5 CMD ADDR DATA CRC
	//
	// CMD:
	//   01 = READ
	//   02 = WRITE
	//
	// Response:
	//
	//   5A STATUS ADDR DATA CRC
	//
	// Complete transaction:
	//
	// MOSI:
	//   A5 CMD ADDR DATA CRC  00 00 00 00 00
	//
	// MISO:
	//   xx xx  xx   xx  xx   5A STATUS ADDR DATA CRC
	//
	// CRC8:
	//   polynomial = 0x07
	//   init       = 0x00
	//   MSB first
	//
	// Address map:
	//
	//   0 .. RW_REG_COUNT-1
	//      RW
	//
	//   RO_BASE_ADDR ..
	//   RO_BASE_ADDR+RO_REG_COUNT-1
	//      RO
	//
	// Maximum total = 256 registers
	// ============================================================

	// ============================================================
	// Commands
	// ============================================================
	localparam [7:0] CMD_READ  = 8'h01;
	localparam [7:0] CMD_WRITE = 8'h02;

	// ============================================================
	// Status
	// ============================================================
	localparam [7:0] STATUS_OK        = 8'h00;
	localparam [7:0] STATUS_BAD_CMD   = 8'h01;
	localparam [7:0] STATUS_BAD_ADDR  = 8'h02;
	localparam [7:0] STATUS_READ_ONLY = 8'h03;
	localparam [7:0] STATUS_BAD_CRC   = 8'h04;

	// ============================================================
	// State machine
	// ============================================================
	localparam [1:0] ST_SEARCH = 2'd0;
	localparam [1:0] ST_RX     = 2'd1;
	localparam [1:0] ST_TX     = 2'd2;
	localparam [1:0] ST_TX_END = 2'd3;

	reg [1:0] state;

	// ============================================================
	// Timeout
	// ============================================================
	localparam integer SPI_TIMEOUT_TICKS_RAW = (CLK_FREQ_HZ / 1000000) * SPI_TIMEOUT_US;

	localparam integer SPI_TIMEOUT_TICKS = (SPI_TIMEOUT_TICKS_RAW < 1)
		? 1 : SPI_TIMEOUT_TICKS_RAW;

	reg [31:0] spi_timeout_counter;

	// ============================================================
	// LED timer
	// ============================================================
	localparam integer LED_TICKS_RAW = (CLK_FREQ_HZ / 1000) * LED_TIME_MS;

	localparam integer LED_TICKS = (LED_TICKS_RAW < 1) ? 1 : LED_TICKS_RAW;

	reg [31:0] led_counter;

	wire led_active;

	assign led_active = (led_counter != 0);

	assign led = LED_ACTIVE_LOW ? ~led_active :  led_active;

	// ============================================================
	// RW registers
	// ============================================================
	reg [7:0] rw_regs [0:RW_REG_COUNT-1];

	genvar g;

	generate
		for (g = 0; g < RW_REG_COUNT; g = g + 1)
		begin : GEN_RW_OUT
			assign rw_regs_out[g*8 +: 8] = rw_regs[g];
		end
	endgenerate

	// ============================================================
	// CRC8
	//
	// polynomial = 0x07
	// init       = 0x00
	// MSB first
	// ============================================================
	function [7:0] crc8_next;
		input [7:0] crc;
		input [7:0] data;

		integer i;
		reg [7:0] c;

		begin
			c = crc ^ data;
			for (i = 0; i < 8; i = i + 1)
			begin
				if (c[7])
					c = (c << 1) ^ 8'h07;
				else
					c = c << 1;
			end
			crc8_next = c;
		end
	endfunction

	// ============================================================
	// Response CRC:
	//
	// 5A STATUS ADDR DATA
	// ============================================================
	function [7:0] response_crc;
		input [7:0] status;
		input [7:0] addr;
		input [7:0] data;
		reg [7:0] c;

		begin
			c = 8'h00;
			c = crc8_next(c, 8'h5A);
			c = crc8_next(c, status);
			c = crc8_next(c, addr);
			c = crc8_next(c, data);
			response_crc = c;
		end
	endfunction

	// ============================================================
	// Read RO register
	// ============================================================
	function [7:0] get_ro;
		input [7:0] idx;
		begin
			get_ro = ro_regs_in[(idx * 8) +: 8];
		end
	endfunction

	// ============================================================
	// Synchronizers
	// ============================================================
	reg sclk_ff1;
	reg sclk_ff2;
	reg sclk_ff2_d;

	reg mosi_ff1;
	reg mosi_ff2;

	wire sclk_rise;
	wire sclk_fall;
	wire sclk_edge;

	assign sclk_rise = sclk_ff2 & ~sclk_ff2_d;
	assign sclk_fall = ~sclk_ff2 & sclk_ff2_d;
	assign sclk_edge = sclk_rise | sclk_fall;

	// ============================================================
	// RX
	// ============================================================
	reg [7:0] rx_shift;

	reg [2:0] rx_bit_count;
	reg [2:0] rx_byte_index;

	reg [7:0] cmd_reg;
	reg [7:0] addr_reg;
	reg [7:0] data_reg;

	reg [7:0] crc_calc;

	wire [7:0] rx_full_byte;

	assign rx_full_byte = {
			rx_shift[6:0],
			mosi_ff2
		};

	// ============================================================
	// TX
	// ============================================================
	reg [7:0] resp_status;
	reg [7:0] resp_addr;
	reg [7:0] resp_data;
	reg [7:0] resp_crc;

	reg [2:0] tx_byte_index;
	reg [2:0] tx_bit_index;

	reg tx_done_pending;

	wire [7:0] tx_current_byte;

	assign tx_current_byte = (tx_byte_index == 3'd0)
		? 8'h5A :
		(tx_byte_index == 3'd1)
		? resp_status :
		(tx_byte_index == 3'd2)
		? resp_addr :
		(tx_byte_index == 3'd3)
		? resp_data :
		  resp_crc;

	// ============================================================
	// Timeout
	// ============================================================
	wire timeout_expired;

	assign timeout_expired = (state != ST_SEARCH) &&
		(!sclk_edge) &&
		(spi_timeout_counter >= (SPI_TIMEOUT_TICKS - 1));

	// ============================================================
	// Main
	// ============================================================
	integer n;

	always @(posedge clk or negedge rst_n)
	begin
		if (!rst_n)
		begin
			// ----------------------------------------------------
			// Synchronizers
			// ----------------------------------------------------
			sclk_ff1   <= 1'b0;
			sclk_ff2   <= 1'b0;
			sclk_ff2_d <= 1'b0;

			mosi_ff1 <= 1'b0;
			mosi_ff2 <= 1'b0;

			// ----------------------------------------------------
			// State
			// ----------------------------------------------------
			state <= ST_SEARCH;

			// ----------------------------------------------------
			// RX
			// ----------------------------------------------------
			rx_shift      <= 8'h00;
			rx_bit_count  <= 3'd0;
			rx_byte_index <= 3'd0;

			cmd_reg  <= 8'h00;
			addr_reg <= 8'h00;
			data_reg <= 8'h00;

			crc_calc <= 8'h00;

			// ----------------------------------------------------
			// TX
			// ----------------------------------------------------
			resp_status <= 8'h00;
			resp_addr   <= 8'h00;
			resp_data   <= 8'h00;
			resp_crc    <= 8'h00;

			tx_byte_index <= 3'd0;
			tx_bit_index  <= 3'd7;

			tx_done_pending <= 1'b0;

			max10_tx <= 1'b0;

			// ----------------------------------------------------
			// Timeout
			// ----------------------------------------------------
			spi_timeout_counter <= 32'd0;

			// ----------------------------------------------------
			// LED
			// ----------------------------------------------------
			led_counter <= 32'd0;

			// ----------------------------------------------------
			// RW registers
			// ----------------------------------------------------
			for (n = 0; n < RW_REG_COUNT; n = n + 1)
			begin
				rw_regs[n] <= 8'h00;
			end
		end
		else
		begin
			// ====================================================
			// Synchronizers
			// ====================================================
			sclk_ff1   <= m7_clk;
			sclk_ff2   <= sclk_ff1;
			sclk_ff2_d <= sclk_ff2;

			mosi_ff1 <= m7_tx;
			mosi_ff2 <= mosi_ff1;

			// ====================================================
			// LED
			// ====================================================
			if (led_counter != 0)
			begin
				led_counter <= led_counter - 1'b1;
			end

			// ====================================================
			// Timeout counter
			// ====================================================
			if (state == ST_SEARCH)
			begin
				spi_timeout_counter <= 32'd0;
			end
			else if (sclk_edge)
			begin
				spi_timeout_counter <= 32'd0;
			end
			else
			begin
				if (spi_timeout_counter < (SPI_TIMEOUT_TICKS - 1))
				begin
					spi_timeout_counter <= spi_timeout_counter + 1'b1;
				end
			end

			// ====================================================
			// Timeout has highest priority
			// ====================================================
			if (timeout_expired)
			begin
				state <= ST_SEARCH;

				// RX
				rx_shift <= 8'h00;
				rx_bit_count <= 3'd0;
				rx_byte_index <= 3'd0;
				crc_calc <= 8'h00;

				// TX
				tx_byte_index <= 3'd0;
				tx_bit_index <= 3'd7;
				tx_done_pending <= 1'b0;
				max10_tx <= 1'b0;
				spi_timeout_counter <= 32'd0;
			end
			else
			begin
				// =================================================
				// State machine
				// =================================================
				case (state)
					// =============================================
					// SEARCH
					//
					// Search for A5 bit-by-bit.
					//
					// A5 is special ONLY here.
					// =============================================
					ST_SEARCH:
					begin
						max10_tx <= 1'b0;

						if (sclk_rise)
						begin
							rx_shift <= rx_full_byte;

							if (rx_full_byte == 8'hA5)
							begin
								state <= ST_RX;
								rx_bit_count <= 3'd0;
								rx_byte_index <= 3'd1;
								crc_calc <= crc8_next(8'h00, 8'hA5);
							end
						end
					end

					// =============================================
					// RECEIVE
					//
					// byte 1 = CMD
					// byte 2 = ADDR
					// byte 3 = DATA
					// byte 4 = CRC
					// =============================================
					ST_RX:
					begin
						if (sclk_rise)
						begin
							rx_shift <= rx_full_byte;

							if (rx_bit_count == 3'd7)
							begin
								rx_bit_count <= 3'd0;

								case (rx_byte_index)

									// =============================
									// CMD
									// =============================
									3'd1:
									begin
										cmd_reg <= rx_full_byte;
										crc_calc <= crc8_next(crc_calc, rx_full_byte);
										rx_byte_index <= 3'd2;
									end

									// =============================
									// ADDR
									// =============================
									3'd2:
									begin
										addr_reg <= rx_full_byte;
										crc_calc <= crc8_next(crc_calc, rx_full_byte);
										rx_byte_index <= 3'd3;
									end

									// =============================
									// DATA
									// =============================
									3'd3:
									begin
										data_reg <= rx_full_byte;
										crc_calc <= crc8_next(crc_calc, rx_full_byte);
										rx_byte_index <= 3'd4;
									end

									// =============================
									// CRC
									// =============================
									3'd4:
									begin
										// -------------------------
										// Prepare TX
										// -------------------------
										resp_addr <= addr_reg;
										tx_byte_index <= 3'd0;
										tx_bit_index <= 3'd7;
										tx_done_pending <= 1'b0;
										state <= ST_TX;

										// =========================
										// BAD CRC
										// =========================
										if (rx_full_byte !=
											crc_calc)
										begin
											resp_status <= STATUS_BAD_CRC;
											resp_data <= 8'h00;
											resp_crc <= response_crc(STATUS_BAD_CRC, addr_reg, 8'h00);
										end

										// =========================
										// READ
										// =========================
										else if (cmd_reg == CMD_READ)
										begin
											// ---------------------
											// RW
											// ---------------------
											if (addr_reg < RW_REG_COUNT)
											begin
												resp_status <= STATUS_OK;
												resp_data <= rw_regs[addr_reg];
												resp_crc <= response_crc(STATUS_OK, addr_reg, rw_regs[addr_reg]);
												led_counter <= LED_TICKS;
											end

											// ---------------------
											// RO
											// ---------------------
											else if ((addr_reg >= RO_BASE_ADDR) && (addr_reg < (RO_BASE_ADDR + RO_REG_COUNT)))
											begin
												resp_status <= STATUS_OK;
												resp_data <= get_ro(addr_reg - RO_BASE_ADDR);
												resp_crc <= response_crc(STATUS_OK, addr_reg, get_ro(addr_reg - RO_BASE_ADDR));
												led_counter <= LED_TICKS;
											end

											// ---------------------
											// Bad address
											// ---------------------
											else
											begin
												resp_status <= STATUS_BAD_ADDR;
												resp_data <= 8'h00;
												resp_crc <= response_crc(STATUS_BAD_ADDR, addr_reg, 8'h00);
											end
										end

										// =========================
										// WRITE
										// =========================
										else if (cmd_reg == CMD_WRITE)
										begin
											// ---------------------
											// RW
											// ---------------------
											if (addr_reg < RW_REG_COUNT)
											begin
												rw_regs[addr_reg] <= data_reg;

												resp_status <= STATUS_OK;
												resp_data <= data_reg;
												resp_crc <= response_crc(STATUS_OK, addr_reg, data_reg);
												led_counter <= LED_TICKS;
											end

											// ---------------------
											// RO
											// ---------------------
											else if ((addr_reg >= RO_BASE_ADDR) && (addr_reg < (RO_BASE_ADDR + RO_REG_COUNT)))
											begin
												resp_status <= STATUS_READ_ONLY;
												resp_data <= 8'h00;
												resp_crc <= response_crc(STATUS_READ_ONLY, addr_reg, 8'h00);
											end

											// ---------------------
											// Bad address
											// ---------------------
											else
											begin
												resp_status <= STATUS_BAD_ADDR;
												resp_data <= 8'h00;
												resp_crc <= response_crc(STATUS_BAD_ADDR, addr_reg, 8'h00);
											end
										end

										// =========================
										// Bad command
										// =========================
										else
										begin
											resp_status <= STATUS_BAD_CMD;
											resp_data <= 8'h00;
											resp_crc <= response_crc(STATUS_BAD_CMD, addr_reg, 8'h00);
										end
									end

									// =============================
									// Should never happen
									// =============================
									default:
									begin
										state <= ST_SEARCH;
										rx_bit_count <= 3'd0;
										rx_byte_index <= 3'd0;
									end
								endcase
							end
							else
							begin
								rx_bit_count <= rx_bit_count + 1'b1;
							end
						end
					end

					// =============================================
					// TRANSMIT
					//
					// SPI mode 0:
					//
					// change MISO on falling SCK
					// master samples on rising SCK
					// =============================================
					ST_TX:
					begin
						// -----------------------------------------
						// Set next MISO bit on falling edge
						// -----------------------------------------
						if (sclk_fall)
						begin
							max10_tx <= tx_current_byte[tx_bit_index];

							// -------------------------------------
							// End of current byte
							// -------------------------------------
							if (tx_bit_index == 3'd0)
							begin
								tx_bit_index <= 3'd7;

								// ---------------------------------
								// Last response byte
								// ---------------------------------
								if (tx_byte_index == 3'd4)
								begin
									//
									// Last bit has just been
									// placed on MISO.
									//
									// Do NOT clear it yet.
									//
									// Wait until M7 samples it
									// on the following rising edge.
									//
									tx_done_pending <= 1'b1;
								end
								else
								begin
									tx_byte_index <= tx_byte_index + 1'b1;
								end
							end
							else
							begin
								tx_bit_index <= tx_bit_index - 1'b1;
							end
						end

						// -----------------------------------------
						// Last bit has now been sampled by M7.
						//
						// IMPORTANT:
						//
						// Do NOT set max10_tx=0 here.
						//
						// Keep last MISO bit stable until the
						// following falling edge.
						// -----------------------------------------
						if (sclk_rise && tx_done_pending)
						begin
							tx_done_pending <= 1'b0;
							state <= ST_TX_END;
						end
					end

					// =============================================
					// TX END
					//
					// The last response bit was sampled by M7 on
					// the previous rising edge.
					//
					// Keep MISO stable during entire HIGH phase.
					//
					// Only after SCK falls may MISO return to 0.
					// =============================================
					ST_TX_END:
					begin
						if (sclk_fall)
						begin
							max10_tx <= 1'b0;
							state <= ST_SEARCH;

							// -------------------------------------
							// Reset RX state
							// -------------------------------------
							rx_shift <= 8'h00;
							rx_bit_count <= 3'd0;
							rx_byte_index <= 3'd0;
							crc_calc <= 8'h00;

							// -------------------------------------
							// Reset TX state
							// -------------------------------------
							tx_byte_index <= 3'd0;
							tx_bit_index <= 3'd7;
							tx_done_pending <= 1'b0;
						end
					end

					// =============================================
					// Invalid state
					// =============================================
					default:
					begin
						state <= ST_SEARCH;
						max10_tx <= 1'b0;
						rx_shift <= 8'h00;
						rx_bit_count <= 3'd0;
						rx_byte_index <= 3'd0;
						tx_done_pending <= 1'b0;
					end
				endcase
			end
		end
	end

	// ============================================================
	// Parameter checks
	// ============================================================
	initial
	begin
		if (RW_REG_COUNT < 1)
			$error("spi_client: RW_REG_COUNT must be >= 1");

		if (RW_REG_COUNT > 256)
			$error("spi_client: RW_REG_COUNT must be <= 256");

		if (RO_REG_COUNT < 1)
			$error("spi_client: RO_REG_COUNT must be >= 1");

		if (RO_BASE_ADDR > 8'hFF)
			$error("spi_client: RO_BASE_ADDR must be <= 0xFF");

		if ((RO_BASE_ADDR + RO_REG_COUNT) > 256)
			$error("spi_client: RO address range exceeds 0xFF");

		if (RW_REG_COUNT > RO_BASE_ADDR)
			$error("spi_client: RW and RO address ranges overlap");
	end
endmodule
