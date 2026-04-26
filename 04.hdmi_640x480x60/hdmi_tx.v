module lvds_tx (
    input wire tx_inclock,
    input wire tx_coreclock,
    input wire [29:0] tx_in,

    output wire [2:0] tx_out_p,
    output wire [2:0] tx_out_n
);

    wire [2:0] tx_out;

    soft_lvds_ip soft_lvds_ip_inst (
        .tx_inclock(tx_inclock),
        .tx_syncclock(tx_coreclock),
        .tx_in(tx_in),
        .tx_out(tx_out)
    );

    assign tx_out_p = tx_out;
    assign tx_out_n = ~tx_out;

endmodule