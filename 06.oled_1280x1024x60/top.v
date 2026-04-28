module top (
	input  wire clk_25mhz,  // PIN_L3, 10 MHz
	input  wire rst_n,      // PIN_R15
//	output reg  led0,       // PIN_M16
//	output wire led1,       // PIN_N16
//	output wire led2,       // PIN_P16
//	output wire led3        // PIN_R16
	output wire oled_vclk,  // PIN_L16
	output wire oled_vs,    // PIN_J15
	output wire oled_hs,    // PIN_J16
	output wire oled_de     // PIN_H15
);

		/* PLL */
	wire pllclk_108mhz;
	wire pll_locked;

	altpll_ip altpll_inst (
		.areset (~rst_n),
		.inclk0 (clk_25mhz),
		.c0     (pllclk_108mhz),     // 25*108/25 = 108 MHz
		.locked (pll_locked)
	);

//	wire oled_vclk;
//	wire oled_hs;
//	wire oled_vs;
//	wire oled_de;
	wire [7:0] red;
	wire [7:0] green;
	wire [7:0] blue;
	assign oled_vclk = pllclk_108mhz;
	image_generator image_generator_impl(
		.Clock(oled_vclk),
		.Reset(rst_n),
		.HS(oled_hs),
		.VS(oled_vs),
		.DE(oled_de),
		.R(red),
		.G(green),
		.B(blue)
	);

endmodule

/*
10M08DAF256C8GES
10 MHz
*/
