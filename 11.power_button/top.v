module top (
	input  wire clk,       // L3, 10 MHz
	input  wire rst_n,     // R15
	input  wire button1l,  // B16
	output wire led        // M16
);

	localparam integer CLK_FREQ_HZ = 10_000_000;
	localparam integer DEBOUNCE_MS = 20;
	localparam integer POWER_BUTTON_ON_LONG_PRESS_MS = 1;
	localparam integer POWER_BUTTON_OFF_LONG_PRESS_MS = 1000;
	localparam integer INITIAL_POWER_ON = 1'b0;

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

		/* power_on */
	wire power_on;
	button_on_off_controller #(
		.CLK_FREQ_HZ(CLK_FREQ_HZ),
		.BUTTON_ON_LONG_PRESS_MS(POWER_BUTTON_ON_LONG_PRESS_MS),
		.BUTTON_OFF_LONG_PRESS_MS(POWER_BUTTON_OFF_LONG_PRESS_MS),
		.INITIAL_OUT_STATE(INITIAL_POWER_ON)
	) power_on_off_controller (
		.clk(clk),
		.reset(~rst_n),
		.button_pressed(button1l_pressed),
		.button_released(button1l_released),
		.out_state(power_on)
	);
	
	assign led = ~power_on;
endmodule

/*
10M08DAF256C8GES
10 MHz
*/
