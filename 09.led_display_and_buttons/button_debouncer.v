module button_debouncer #(
    parameter integer CLK_FREQ_HZ   = 25_000_000,
    parameter integer DEBOUNCE_MS   = 20,
    parameter integer COUNTER_MAX   = (CLK_FREQ_HZ / 1000) * DEBOUNCE_MS
)(
    input  wire clk,
    input  wire reset,

    input  wire button_in,       // surowy sygnał z przycisku
    output reg  button_out,      // stabilny stan przycisku
    output reg  button_pressed,  // impuls 1 takt przy naciśnięciu
    output reg  button_released  // impuls 1 takt przy puszczeniu
);

    // ------------------------------------------------------------
    // Synchronizacja wejścia asynchronicznego do domeny clk
    // ------------------------------------------------------------
    reg sync_0;
    reg sync_1;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            sync_0 <= 1'b0;
            sync_1 <= 1'b0;
        end else begin
            sync_0 <= button_in;
            sync_1 <= sync_0;
        end
    end

    // ------------------------------------------------------------
    // Debouncer
    // ------------------------------------------------------------
    reg [$clog2(COUNTER_MAX + 1)-1:0] counter;
    reg button_state_prev;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            counter         <= 0;
            button_out      <= 1'b0;
            button_state_prev <= 1'b0;
            button_pressed  <= 1'b0;
            button_released <= 1'b0;
        end else begin
            button_pressed  <= 1'b0;
            button_released <= 1'b0;

            if (sync_1 == button_out) begin
                counter <= 0;
            end else begin
                if (counter < COUNTER_MAX - 1) begin
                    counter <= counter + 1'b1;
                end else begin
                    counter <= 0;
                    button_out <= sync_1;

                    if (sync_1 == 1'b1) begin
                        button_pressed <= 1'b1;
                    end else begin
                        button_released <= 1'b1;
                    end
                end
            end
        end
    end

endmodule
