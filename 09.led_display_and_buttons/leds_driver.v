module number_to_7seg (
	input  wire [3:0] digit,
	output reg  [6:0] segments
);
	localparam [6:0] DIGIT_0 = 7'b1111110;
	localparam [6:0] DIGIT_1 = 7'b0110000;
	localparam [6:0] DIGIT_2 = 7'b1101101;
	localparam [6:0] DIGIT_3 = 7'b1111001;
	localparam [6:0] DIGIT_4 = 7'b0110011;
	localparam [6:0] DIGIT_5 = 7'b1011011;
	localparam [6:0] DIGIT_6 = 7'b1011111;
	localparam [6:0] DIGIT_7 = 7'b1110000;
	localparam [6:0] DIGIT_8 = 7'b1111111;
	localparam [6:0] DIGIT_9 = 7'b1111011;

	always @(*) begin
		case (digit)
			4'd0: segments = DIGIT_0;
			4'd1: segments = DIGIT_1;
			4'd2: segments = DIGIT_2;
			4'd3: segments = DIGIT_3;
			4'd4: segments = DIGIT_4;
			4'd5: segments = DIGIT_5;
			4'd6: segments = DIGIT_6;
			4'd7: segments = DIGIT_7;
			4'd8: segments = DIGIT_8;
			4'd9: segments = DIGIT_9;
			default: segments = 7'b0000000;
		endcase
	end
endmodule

module leds_driver #(
	parameter integer CLK_FREQ_HZ = 10_000_000
)(
	input  wire        clk,
	input  wire        reset,
	input  wire [13:0] number,
	output reg  [6:0]  led_anode_digits,
	output wire        led_anode_dot,
	output reg  [3:0]  led_kathode
);

	localparam integer LEDS_COUNTER_MAX = CLK_FREQ_HZ / 500; // 500 Hz LEDs multiplexing

	assign led_anode_dot = 1'b0;

	wire [6:0]  leds1;
	wire [6:0]  leds2;
	wire [6:0]  leds3;
	wire [6:0]  leds4;
	reg  [25:0] leds_counter;
	reg  [2:0]  leds_row;

	number_to_7seg number_to_7seg_1 (
		.digit(number % 10),
		.segments(leds1)
	);
	number_to_7seg number_to_7seg_2 (
		.digit((number / 10) % 10),
		.segments(leds2)
	);
	number_to_7seg number_to_7seg_3 (
		.digit((number / 100) % 10),
		.segments(leds3)
	);
	number_to_7seg number_to_7seg_4 (
		.digit((number / 1000) % 10),
		.segments(leds4)
	);

	always @(posedge clk or posedge reset) begin
		if (reset) begin
			leds_counter <= 26'd0;
			leds_row <= 3'd0;
			led_anode_digits <= 7'd0;
			led_kathode <= 4'd0;
		end else begin
			if (leds_counter == LEDS_COUNTER_MAX) begin
				leds_counter <= 26'd0;

				if (leds_row == 3)
					leds_row <= 3'd0;
				else
					leds_row <= leds_row + 1'b1;

				case (leds_row)
					0 + 1: begin      // row 0
						led_anode_digits <= leds1;
						led_kathode <= 4'b0001;
						end
					1 + 1: begin      // row 1
						led_anode_digits <= leds2;
						led_kathode <= 4'b0010;
						end
					2 + 1: begin      // row 2
						led_anode_digits <= leds3;
						led_kathode <= 4'b0100;
						end
					3 + 1 - 4: begin  // row 3
						led_anode_digits <= leds4;
						led_kathode <= 4'b1000;
						end
				endcase
			end else
				leds_counter <= leds_counter + 1'b1;
		end
	end
endmodule
