module button_autorepeat #(
    parameter integer CLK_FREQ_HZ       = 25_000_000,
    parameter integer FIRST_DELAY_MS    = 1000,
    parameter integer REPEAT_PERIOD_MS  = 500,

    parameter integer FIRST_DELAY_CYCLES =
        (CLK_FREQ_HZ / 1000) * FIRST_DELAY_MS,

    parameter integer REPEAT_PERIOD_CYCLES =
        (CLK_FREQ_HZ / 1000) * REPEAT_PERIOD_MS
)(
    input  wire clk,
    input  wire reset,

    input  wire button_stable,   // button_out z debouncera
    input  wire button_pressed,  // button_pressed z debouncera

    output reg  repeat_pulse     // impuls 1 takt
);

    reg [$clog2(FIRST_DELAY_CYCLES + 1)-1:0] first_counter;
    reg [$clog2(REPEAT_PERIOD_CYCLES + 1)-1:0] repeat_counter;

    reg repeating;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            first_counter  <= 0;
            repeat_counter <= 0;
            repeating      <= 1'b0;
            repeat_pulse   <= 1'b0;
        end else begin
            repeat_pulse <= 1'b0;

            if (!button_stable) begin
                first_counter  <= 0;
                repeat_counter <= 0;
                repeating      <= 1'b0;
            end else begin

                if (!repeating) begin
                    if (first_counter < FIRST_DELAY_CYCLES - 1) begin
                        first_counter <= first_counter + 1'b1;
                    end else begin
                        first_counter  <= 0;
                        repeat_counter <= 0;
                        repeating      <= 1'b1;
                        repeat_pulse   <= 1'b1;   // pierwszy impuls po 1 sekundzie
                    end
                end else begin
                    if (repeat_counter < REPEAT_PERIOD_CYCLES - 1) begin
                        repeat_counter <= repeat_counter + 1'b1;
                    end else begin
                        repeat_counter <= 0;
                        repeat_pulse   <= 1'b1;   // kolejne impulsy co 0.5 sekundy
                    end
                end

            end
        end
    end
endmodule
