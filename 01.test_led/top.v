module top (
	input  wire clk,      // PIN_L3, 10 MHz
	input  wire rst_n,    // PIN_R15
	output reg  led       // PIN_M16
);

	localparam integer CLK_HZ = 10_000_000;
	localparam integer CNT_MAX = (CLK_HZ / 2) - 1;

	reg [24:0] counter;

	always @(posedge clk or negedge rst_n) begin
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
