module top (
	input  wire clk,      // PIN_L3, 10 MHz
	input  wire rst_n,    // PIN_R15
	output reg  led       // PIN_M16
);

	localparam integer CLK_HZ = 25_000_000;
	localparam integer CNT_MAX = (CLK_HZ / 2) - 1;
	
	wire pll_clock;     // 25.16854 MHz (near 25.175 MHz VGA 640x480x60)
	wire pll_locked;

	altpll_inst altpll_inst1 (  // 10 MHz * 224 / 89 = 25.16854 MHz
		.areset (~rst_n),
		.inclk0 (clk),
		.c0     (pll_clock),
		.locked (pll_locked)
	);

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
