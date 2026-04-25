//`include "synthesis_directives.v"
`define WIDTH  640
`define HEIGHT 480

`define IMAGE_STATE_RECTANGLE	4'b0001		// ImageState - state machine
`define IMAGE_STATE_V_BARS		4'b0010
`define IMAGE_STATE_H_BARS		4'b0100

//`define	INITIAL_IMAGE_STATE		`IMAGE_STATE_RECTANGLE
//`define	INITIAL_IMAGE_STATE		`IMAGE_STATE_V_BARS
`define	INITIAL_IMAGE_STATE		`IMAGE_STATE_H_BARS

`define VERTICAL_LINE
`define CHANGE_IMAGE

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
`define Y8_0_7 (255 * 0 / 7)
`define Y8_1_7 (255 * 1 / 7)
`define Y8_2_7 (255 * 2 / 7)
`define Y8_3_7 (255 * 3 / 7)
`define Y8_4_7 (255 * 4 / 7)
`define Y8_5_7 (255 * 5 / 7)
`define Y8_6_7 (255 * 6 / 7)
`define Y8_7_7 (255 * 7 / 7)

`define SMPTE_R1 8'hff
`define SMPTE_G1 8'hff
`define SMPTE_B1 8'hff
`define SMPTE_R2 8'hff
`define SMPTE_G2 8'hff
`define SMPTE_B2 8'h00
`define SMPTE_R3 8'h00
`define SMPTE_G3 8'hff
`define SMPTE_B3 8'hff
`define SMPTE_R4 8'h00
`define SMPTE_G4 8'hff
`define SMPTE_B4 8'h00
`define SMPTE_R5 8'hff
`define SMPTE_G5 8'h00
`define SMPTE_B5 8'hff
`define SMPTE_R6 8'hff
`define SMPTE_G6 8'h00
`define SMPTE_B6 8'h00
`define SMPTE_R7 8'h00
`define SMPTE_G7 8'h00
`define SMPTE_B7 8'hff
`define SMPTE_R8 8'h00
`define SMPTE_G8 8'h00
`define SMPTE_B8 8'h00

module test_screens_generator(
	input Clock,
	input [11:0] x,
	input [11:0] y,
	input wire DE,
	output reg [7:0] red,
	output reg [7:0] green,
	output reg [7:0] blue
);

	reg [3:0] ImageState = `INITIAL_IMAGE_STATE;		// state machine
	parameter IMAGE_COUNTER_MAX = 180;					// zmiana obrazu co 180 klatek - 3s (60kl/s)
	reg [11:0] ImageCounter = IMAGE_COUNTER_MAX;
	reg [11:0] VerticalLineCounter = 12'd0;

	always @(negedge Clock) begin
		if (~DE) begin       // pixels outside screen
			red   <= 8'h00;
			green <= 8'h00;
			blue  <= 8'h00;
		end
		else
		begin
			if (ImageState == `IMAGE_STATE_RECTANGLE) begin
				if ((y == 0) || (y == `HEIGHT - 1) || (x == 0) || (x == `WIDTH - 1)) begin
					red   <= 8'hff;
					green <= 8'hff;
					blue  <= 8'hff;
				end
				else begin
					red   <= 8'h00;
					green <= 8'h00;
					blue  <= 8'h00;
				end
			end
			else
			if (ImageState == `IMAGE_STATE_V_BARS) begin
				if (y < `HEIGHT_1_8) begin
					red   <= `SMPTE_R1;
					green <= `SMPTE_G1;
					blue  <= `SMPTE_B1;
				end
				else if (y < `HEIGHT_2_8) begin
					red   <= `SMPTE_R2;
					green <= `SMPTE_G2;
					blue  <= `SMPTE_B2;
				end
				else if (y < `HEIGHT_3_8) begin
					red   <= `SMPTE_R3;
					green <= `SMPTE_G3;
					blue  <= `SMPTE_B3;
				end
				else if (y < `HEIGHT_4_8) begin
					red   <= `SMPTE_R4;
					green <= `SMPTE_G4;
					blue  <= `SMPTE_B4;
				end
				else if (y < `HEIGHT_5_8) begin
					red   <= `SMPTE_R5;
					green <= `SMPTE_G5;
					blue  <= `SMPTE_B5;
				end
				else if (y < `HEIGHT_6_8) begin
					red   <= `SMPTE_R6;
					green <= `SMPTE_G6;
					blue  <= `SMPTE_B6;
				end
				else if (y < `HEIGHT_7_8) begin
					red   <= `SMPTE_R7;
					green <= `SMPTE_G7;
					blue  <= `SMPTE_B7;
				end
				else begin  // if (y < `HEIGHT)
					red   <= `SMPTE_R8;
					green <= `SMPTE_G8;
					blue  <= `SMPTE_B8;
				end
			end
			else if (ImageState == `IMAGE_STATE_H_BARS) begin
				if (x < `WIDTH_1_8) begin
					red   <= `SMPTE_R1;
					green <= `SMPTE_G1;
					blue  <= `SMPTE_B1;
				end
				else if (x < `WIDTH_2_8) begin
					red   <= `SMPTE_R2;
					green <= `SMPTE_G2;
					blue  <= `SMPTE_B2;
				end
				else if (x < `WIDTH_3_8) begin
					red   <= `SMPTE_R3;
					green <= `SMPTE_G3;
					blue  <= `SMPTE_B3;
				end
				else if (x < `WIDTH_4_8) begin
					red   <= `SMPTE_R4;
					green <= `SMPTE_G4;
					blue  <= `SMPTE_B4;
				end
				else if (x < `WIDTH_5_8) begin
					red   <= `SMPTE_R5;
					green <= `SMPTE_G5;
					blue  <= `SMPTE_B5;
				end
				else if (x < `WIDTH_6_8) begin
					red   <= `SMPTE_R6;
					green <= `SMPTE_G6;
					blue  <= `SMPTE_B6;
				end
				else if (x < `WIDTH_7_8) begin
					red   <= `SMPTE_R7;
					green <= `SMPTE_G7;
					blue  <= `SMPTE_B7;
				end
				else begin  // if (x < `WIDTH)
					red   <= `SMPTE_R8;
					green <= `SMPTE_G8;
					blue  <= `SMPTE_B8;
				end
			end
			
			if (VerticalLineCounter == x) begin
				red   <= ~red;
				green <= ~green;
				blue  <= ~blue;
			end
		end
	end

`ifdef CHANGE_IMAGE
	always @(posedge Clock) begin
		if (DE && x == 0 && y == 0) begin
			ImageCounter <= ImageCounter - 1'b1;
			if (ImageCounter - 1 == 0) begin
				ImageCounter <= IMAGE_COUNTER_MAX;

				case (ImageState)
					`IMAGE_STATE_RECTANGLE  : ImageState <= `IMAGE_STATE_V_BARS;
					`IMAGE_STATE_V_BARS     : ImageState <= `IMAGE_STATE_H_BARS;
					`IMAGE_STATE_H_BARS     : ImageState <= `IMAGE_STATE_RECTANGLE;
					default                 : ImageState <= `IMAGE_STATE_RECTANGLE;
				endcase
			end
		end
	end
`endif

`ifdef VERTICAL_LINE
	always @(posedge Clock) begin
		if (DE && x == 0 && y == 0) begin
			VerticalLineCounter <= VerticalLineCounter + 1'd1;
			if (VerticalLineCounter == `WIDTH)
				VerticalLineCounter <= 12'd0;
		end
`endif
	end

endmodule
