//`define COUNT

module top (
	input  wire       clk,               // L3, 10 MHz
	input  wire       rst_n,             // R15
	output wire [6:0] led_anode_digits,  // L16 J15 J16 H15 H16 G15 G16 - U UR DR D DL UL M
	output wire       led_anode_dot,     // F16 - dot
	output wire [3:0] led_kathode,       // D16 D15 E16 E15 - left to right
	input  wire       button1l,          // B16
	input  wire       button2r           // B15
);

	localparam integer CLK_FREQ_HZ = 10_000_000;
	localparam integer NUMBER_COUNTER_MAX = CLK_FREQ_HZ / 10; // increase 10 / 1 second
	localparam integer AUTOREPEAT_FIRST_DELAY_MS    = 1000;
	localparam integer AUTOREPEAT_REPEAT_PERIOD_MS  = 500;

	reg [13:0] number = 14'd0;

		/* auto increase counter */
`ifdef COUNT
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
`endif

		/* debouncer button 1 L */
	wire button1l_stable;
	wire button1l_pressed;
	wire button1l_released;
	button_debouncer #(
		.CLK_FREQ_HZ(CLK_FREQ_HZ)
	) button_debouncer_1l (
		.clk(clk),
		.reset(~rst_n),
		.button_in(~button1l),
		.button_out(button1l_stable),
		.button_pressed(button1l_pressed),
		.button_released(button1l_released)
	);

		/* debouncer button 2 R */
	wire button2r_stable;
	wire button2r_pressed;
	wire button2r_released;
	button_debouncer #(
		.CLK_FREQ_HZ(CLK_FREQ_HZ)
	) button_debouncer_2r (
		.clk(clk),
		.reset(~rst_n),
		.button_in(~button2r),
		.button_out(button2r_stable),
		.button_pressed(button2r_pressed),
		.button_released(button2r_released)
	);

		/* autorepeat button 1 L */
	wire button1l_pulse;
	button_autorepeat #(
		.CLK_FREQ_HZ(CLK_FREQ_HZ),
		.FIRST_DELAY_MS(AUTOREPEAT_FIRST_DELAY_MS),
		.REPEAT_PERIOD_MS(AUTOREPEAT_REPEAT_PERIOD_MS)
	) button_autorepeat_1l (
		.clk(clk),
		.reset(~rst_n),
		.button_stable(button1l_stable),
		.button_pressed(button1l_pressed),
		.repeat_pulse(button1l_pulse)
	);

		/* autorepeat button 2 R */
	wire button2r_pulse;
	button_autorepeat #(
		.CLK_FREQ_HZ(CLK_FREQ_HZ),
		.FIRST_DELAY_MS(AUTOREPEAT_FIRST_DELAY_MS),
		.REPEAT_PERIOD_MS(AUTOREPEAT_REPEAT_PERIOD_MS)
	) button_autorepeat_2r (
		.clk(clk),
		.reset(~rst_n),
		.button_stable(button2r_stable),
		.button_pressed(button2r_pressed),
		.repeat_pulse(button2r_pulse)
	);

		/* increase number */
	always @(posedge clk or negedge rst_n) begin
		if (~rst_n)
			number <= 14'd0;
		else begin
			if (button1l_pressed)
				number <= number + 1'b1;
			else if (button2r_pressed && number == 14'd0)
				number <= 14'd9999;
			else if (button2r_pressed)
				number <= number - 1'b1;
			
			if (button1l_pulse)
				number <= number + 5'd10;
			else if (button2r_pulse && number < 5'd10)
				number <= 14'd10000 - number;
			else if (button2r_pulse)
				number <= number - 5'd10;
		end
	end

		/* LEDs driver */
	leds_driver #(
		.CLK_FREQ_HZ(CLK_FREQ_HZ)
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
