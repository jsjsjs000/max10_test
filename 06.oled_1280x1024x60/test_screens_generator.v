 `include "synthesis_directives.v"

`define WIDTH_1_8 (`WIDTH * 1 / 8)
`define WIDTH_2_8 (`WIDTH * 2 / 8)
`define WIDTH_3_8 (`WIDTH * 3 / 8)
`define WIDTH_4_8 (`WIDTH * 4 / 8)
`define WIDTH_5_8 (`WIDTH * 5 / 8)
`define WIDTH_6_8 (`WIDTH * 6 / 8)
`define WIDTH_7_8 (`WIDTH * 7 / 8)
`define HEIGHT_1_8 (`HEIGHT * 1 / 8)
`define HEIGHT_2_8 (`HEIGHT * 2 / 8)
`define HEIGHT_3_8 (`HEIGHT * 3 / 8)
`define HEIGHT_4_8 (`HEIGHT * 4 / 8)
`define HEIGHT_5_8 (`HEIGHT * 5 / 8)
`define HEIGHT_6_8 (`HEIGHT * 6 / 8)
`define HEIGHT_7_8 (`HEIGHT * 7 / 8)

module test_screens_generator(
	input Clock,
	input [3:0] ImageState,
	input [11:0] x,
	input [11:0] y,
	input wire DE,
	output reg [7:0] R,
	output reg [7:0] G,
	output reg [7:0] B
);

	reg [12:0] ColorTmp;		// for 600 * 10, next / 23

	always @(negedge Clock) begin
		if (x == 12'hfff) begin       // $$ po co to?
			R <= 8'h00;
			G <= 8'h00;
			B <= 8'h00;
		end
		else
		begin
			if (ImageState == `IMAGE_STATE_RECTANGLE) begin
				if ((y == 2) || (y == `HEIGHT - 1) || (x == 0) || (x == `WIDTH - 1)) begin  // 2 - margin left
					R <= 8'hff;
					G <= 8'hff;
					B <= 8'hff;
				end
				else begin
					R <= 8'h00;
					G <= 8'h00;
					B <= 8'h00;
				end
			end
			else 
				if (ImageState == `IMAGE_STATE_V_BARS) begin
				if (y < `HEIGHT_1_8) begin
					R <= 8'h00;
					G <= 8'h00;
					B <= 8'h00;
				end
				else if (y < `HEIGHT_2_8) begin
					R <= 8'h00;
					G <= 8'h00;
					B <= 8'hff;
				end
				else if (y < `HEIGHT_3_8) begin
					R <= 8'h00;
					G <= 8'hff;
					B <= 8'h00;
				end
				else if (y < `HEIGHT_4_8) begin
					R <= 8'hff;
					G <= 8'h00;
					B <= 8'h00;
				end
				else if (y < `HEIGHT_5_8) begin
					R <= 8'hff;
					G <= 8'h00;
					B <= 8'hff;
				end
				else if (y < `HEIGHT_6_8) begin
					R <= 8'h00;
					G <= 8'hff;
					B <= 8'hff;
				end
				else if (y < `HEIGHT_7_8) begin
					R <= 8'hff;
					G <= 8'hff;
					B <= 8'h00;
				end
				else begin // if (y < `HEIGHT) begin  // $$ bez if
					R <= 8'hff;
					G <= 8'hff;
					B <= 8'hff;
				end
			end
			else if (ImageState == `IMAGE_STATE_H_BARS) begin
				if (x < `WIDTH_1_8) begin
					R <= 8'h00;
					G <= 8'h00;
					B <= 8'h00;
				end
				else if (x < `WIDTH_2_8) begin
					R <= 8'h00;
					G <= 8'h00;
					B <= 8'hff;
				end
				else if (x < `WIDTH_3_8) begin
					R <= 8'h00;
					G <= 8'hff;
					B <= 8'h00;
				end
				else if (x < `WIDTH_4_8) begin
					R <= 8'hff;
					G <= 8'h00;
					B <= 8'h00;
				end
				else if (x < `WIDTH_5_8) begin
					R <= 8'hff;
					G <= 8'h00;
					B <= 8'hff;
				end
				else if (x < `WIDTH_6_8) begin
					R <= 8'h00;
					G <= 8'hff;
					B <= 8'hff;
				end
				else if (x < `WIDTH_7_8) begin
					R <= 8'hff;
					G <= 8'hff;
					B <= 8'h00;
				end
				else begin // if (x < `WIDTH) begin $$
					R <= 8'hff;
					G <= 8'hff;
					B <= 8'hff;
				end
			end
			else if (ImageState == `IMAGE_STATE_GRAY_SCALE) begin
				R <= ColorTmp[7:0];
				G <= ColorTmp[7:0];
				B <= ColorTmp[7:0];
			end
		end
	end

	always @(posedge Clock) begin
		if (x == 12'hfff)				// on start every line, counting for grayscale
			ColorTmp <= y * 10;
		else if (x == 0)
			ColorTmp <= ColorTmp / 23;
	end
endmodule
