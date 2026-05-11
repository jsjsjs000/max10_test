module top (
	input  wire clk,      // PIN_L3, 10 MHz
	input  wire rst_n,    // PIN_R15
	output reg  led,      // PIN_M16
	output wire hsync,    // PIN_L1
	output wire vsync,    // PIN_J1
	output wire red,      // PIN_R1
	output wire green,    // PIN_N1
	output wire blue      // PIN_M1
);

	localparam integer CLK_HZ = 25_000_000;
	localparam integer CNT_MAX = (CLK_HZ / 2) - 1;

		// PLL
	wire pll_clock;     // 25.16854 MHz (near 25.175 MHz VGA 640x480x60)
	wire pll_locked;

	altpll_inst altpll_inst1 (  // 10 MHz * 224 / 89 = 25.16854 MHz
		.areset (~rst_n),
		.inclk0 (clk),
		.c0     (pll_clock),
		.locked (pll_locked)
	);

		// VGA generator
	wire de;
	wire [9:0] x;
	wire [9:0] y;
	vga_640x480_60 vga_640x480_60_inst1 (
		.clk      (pll_clock),
		.rst      (~rst_n),
		.hsync    (hsync),
		.vsync    (vsync),
		.de       (de),
		.x        (x),
		.y        (y)
	);

		// test screen
	test_screens_generator test_screens_generator_inst (
		.Clock (pll_clock),
		.x  (x),
		.y  (y),
		.DE (de),
		.red  (red),
		.green (green),
		.blue  (blue)
	);

		// simple test screen
//	assign red   = de ? x[7:4] : 0;
////	assign red   = (de && x >= 0 && x <= 32) ? 1 : 0;
//	assign green = de ? y[7:4] : 0;
//	assign blue  = de ? 1'd1 : 1'd0;

		// LED
	reg [26:0] counter;

	always @(posedge pll_clock or negedge rst_n) begin
		if (!rst_n) begin
			counter <= 25'd0;
			led     <= 1'b0;
		end else begin
			if (counter == CNT_MAX) begin
				counter <= 25'd0;
				led     <= ~led;
			end else begin
				counter <= counter + 1'b1;
			end
		end
	end
endmodule

/*
10M08DAF256C8GES
10 MHz
*/
