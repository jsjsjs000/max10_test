module top (
	input  wire clk,      // PIN_L3, 10 MHz
	input  wire rst_n,    // PIN_R15
	output wire hsync,    // PIN_L1
	output wire vsync,    // PIN_J1
	output wire de
);

		// VGA generator
	wire [9:0] x;
	wire [9:0] y;
	vga_640x480_60 vga_640x480_60_inst1 (
		.clk      (clk),
		.rst      (~rst_n),
		.hsync    (hsync),
		.vsync    (vsync),
		.de       (de),
		.x        (x),
		.y        (y)
	);

endmodule

/*
10M08DAF256C8GES
10 MHz
*/
