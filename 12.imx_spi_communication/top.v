module top (
	input  wire clk,       // L3, 10 MHz
	input  wire rst_n,     // R15
	input  wire button1l,  // B16
	output wire led,       // M16

  //          GND               (devboard right4) - i.MX devboard J?.?
	input  wire m7_clk,    // C16 (devboard right5) - i.MX devboard J?.?
	input  wire m7_tx,     // C15 (devboard right6) - i.MX devboard J?.?
	output wire max10_tx   // D16 (devboard right7) - i.MX devboard J?.?
);
	localparam integer CLK_FREQ_HZ = 10_000_000;

	localparam RW_COUNT = 32;
	localparam RO_COUNT = 32;

	reg [32:0] counter;
	reg led_reg;
	always @(posedge clk) begin
		if (rst_n == 1'b0) begin
			counter <= 0;
			led_reg <= 1'b0;
		end else begin
			if (counter >= CLK_FREQ_HZ) begin
				counter <= 0;
				led_reg <= ~led_reg;
			end
			else
				counter <= counter + 1'b1;
		end
	end
	
	wire [(RW_COUNT*8)-1:0] spi_rw_regs;
	reg  [(RO_COUNT*8)-1:0] spi_ro_regs;
	
	spi_client #(
		.CLK_FREQ_HZ     (CLK_FREQ_HZ),
    .SPI_TIMEOUT_US  (5000),
		.LED_TIME_MS     (10),

		.RW_REG_COUNT   (RW_COUNT),
		.RO_REG_COUNT   (RO_COUNT),
		.RO_BASE_ADDR   (8'h80),

		.LED_ACTIVE_LOW (1)
	)
	u_spi_client (
		.clk         (clk),
		.rst_n       (rst_n),

		.m7_clk      (m7_clk),
		.m7_tx       (m7_tx),
		.max10_tx    (max10_tx),

		.rw_regs_out (spi_rw_regs),
		.ro_regs_in  (spi_ro_regs),

		.led         (led)
	);


//	reg	[7:0]		status_reg_0;
//	reg	[7:0]		status_reg_1;
//	wire	[7:0]		control_reg_0;
//	wire	[7:0]		control_reg_1;
//
//	wire	[127:0]		ro_regs_flat;
//	wire	[127:0]		rw_regs_flat;
//	wire			write_strobe;
//	wire	[4:0]		write_addr;
//	wire	[7:0]		write_data;
//
//	assign led = button1l ? control_reg_0[0] : control_reg_1[0];
//
//	always @(posedge clk) begin
//		if (rst_n == 1'b0) begin
//			status_reg_0 <= 8'h00;
//			status_reg_1 <= 8'h00;
//		end else begin
//			status_reg_0 <= status_reg_0 + 8'd1;
//			status_reg_1 <= {button1l, 5'b00000, m7_tx, m7_clk};
//		end
//	end
//
//	assign ro_regs_flat[8*0 +: 8] = status_reg_0;
//	assign ro_regs_flat[8*1 +: 8] = status_reg_1;
//	assign ro_regs_flat[8*2 +: 8] = 8'h00;
//	assign ro_regs_flat[8*3 +: 8] = 8'h00;
//	assign ro_regs_flat[8*4 +: 8] = 8'h00;
//	assign ro_regs_flat[8*5 +: 8] = 8'h00;
//	assign ro_regs_flat[8*6 +: 8] = 8'h00;
//	assign ro_regs_flat[8*7 +: 8] = 8'h00;
//	assign ro_regs_flat[8*8 +: 8] = 8'h00;
//	assign ro_regs_flat[8*9 +: 8] = 8'h00;
//	assign ro_regs_flat[8*10 +: 8] = 8'h00;
//	assign ro_regs_flat[8*11 +: 8] = 8'h00;
//	assign ro_regs_flat[8*12 +: 8] = 8'h00;
//	assign ro_regs_flat[8*13 +: 8] = 8'h00;
//	assign ro_regs_flat[8*14 +: 8] = 8'h00;
//	assign ro_regs_flat[8*15 +: 8] = 8'h00;
//
//	imx_communication u_imx_communication (
//		.clk(clk),
//		.rst_n(rst_n),
//		.m7_clk(m7_clk),
//		.m7_tx(m7_tx),
//		.max10_tx(max10_tx),
//		.ro_regs_flat(ro_regs_flat),
//		.rw_regs_flat(rw_regs_flat),
//		.write_strobe(write_strobe),
//		.write_addr(write_addr),
//		.write_data(write_data)
//	);
//
//	assign control_reg_0 = rw_regs_flat[8*0 +: 8];
//	assign control_reg_1 = rw_regs_flat[8*1 +: 8];



endmodule

/*
10M08DAF256C8GES
10 MHz
*/
