module button_on_off_controller #(
	parameter integer CLK_FREQ_HZ              = 10_000_000,
	parameter integer BUTTON_ON_LONG_PRESS_MS  = 1,
	parameter integer BUTTON_OFF_LONG_PRESS_MS = 1000,
	parameter         INITIAL_OUT_STATE        = 1'b0
)(
	input wire clk,
	input wire reset,
	input wire button_pressed,   // one clock edge
	input wire button_released,  // one clock edge
	output reg out_state
);

	localparam integer BUTTON_ON_LONG_PRESS_TICKS  = (CLK_FREQ_HZ / 1000) * BUTTON_ON_LONG_PRESS_MS;
	localparam integer BUTTON_OFF_LONG_PRESS_TICKS = (CLK_FREQ_HZ / 1000) * BUTTON_OFF_LONG_PRESS_MS;

	reg button_pressed_state;
	reg [24:0] pressed_counter;  // max 33_554_432 ~ 10 sec for 25 MHz clock

	always @(posedge clk or posedge reset) begin
		if (reset) begin
			out_state <= INITIAL_OUT_STATE;
			button_pressed_state <= 1'b0;
			pressed_counter <= 25'd0;
		end else begin
			if (button_pressed) begin
				button_pressed_state <= 1'b1;
				pressed_counter <= 25'd0;
			end else if (button_released) begin
				button_pressed_state <= 1'b0;
			end

			if (button_pressed_state) begin
				pressed_counter <= pressed_counter + 1'b1;
				
				if (~out_state && pressed_counter == BUTTON_ON_LONG_PRESS_TICKS) begin
					out_state <= 1'b1;
					button_pressed_state <= 1'b0;
				end
				if (out_state && pressed_counter == BUTTON_OFF_LONG_PRESS_TICKS) begin
					out_state <= 1'b0;
					button_pressed_state <= 1'b0;
				end
			end
		end
	end
endmodule
