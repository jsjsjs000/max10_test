module top (
	input  wire       clk,               // L3, 10 MHz
	input  wire       rst_n,             // R15
	output wire [6:0] led_anode_digits,  // L16 J15 J16 H15 H16 G15 G16 - U UR DR D DL UL M
	output wire       led_anode_dot,     // F16 - dot
	output wire [3:0] led_kathode,       // D16 D15 E16 E15 - left to right
	input  wire       button1_l,         // B16
	input  wire       button2_r          // B15
);

	localparam integer CLK_HZ = 10_000_000;
	localparam integer NUMBER_COUNTER_MAX = CLK_HZ / 10; // increase 10 / 1 second

	reg [13:0] number = 14'd0;
	reg [25:0] number_counter = 26'd0;

	always @(posedge clk or negedge rst_n) begin
		if (~rst_n) begin
			number <= 14'd0;
			number_counter = 26'd0;
		end else begin
			if (number_counter == NUMBER_COUNTER_MAX) begin
				number_counter <= 26'd0;
				number <= number + 1'b1;
			end else
				number_counter <= number_counter + 1'b1;
		end
	end

	leds_driver #(
		.CLK_HZ(CLK_HZ)
	) leds_driver_inst (
		.clk(clk),
		.reset(~rst_n),
		.number(number),
		.led_anode_digits(led_anode_digits),
		.led_anode_dot(led_anode_dot),
		.led_kathode(led_kathode)
	);

endmodule

/*
10M08DAF256C8GES
10 MHz
*/
