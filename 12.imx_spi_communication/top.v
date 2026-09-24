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

		/* example counter */
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

		/* SPI communication */
	wire [(RW_COUNT*8)-1:0] spi_rw_regs;
	wire [(RO_COUNT*8)-1:0] spi_ro_regs;
	
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

		/* example RO registers */
	wire	[7:0]		status_reg_0;
	wire	[7:0]		status_reg_31;
	assign spi_ro_regs = {
		status_reg_31,
		{ ((RO_COUNT-2)*8){1'b0} },
		status_reg_0
	};
	assign status_reg_0 = counter[7:0];
	assign status_reg_31 = { counter[6:0], 1'b0 };

//	assign ro_regs_flat[8*0 +: 8] = status_reg_0;
//	assign ro_regs_flat[8*1 +: 8] = status_reg_1;

endmodule

/*
10M08DAF256C8GES
10 MHz
*/
