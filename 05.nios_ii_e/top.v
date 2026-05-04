module top(
	input  wire       clk,     // L3
	input  wire       rst_n,   // R15
	input  wire [0:7] inputs,  // B16 Button L
	output wire [0:7] outputs  // M16 LED0
);

	nios_ii_e nios_ii_e_impl (
			.clk_clk        (clk),
			.reset_reset_n  (rst_n),
			.inputs_export  (inputs),
			.outputs_export (outputs)
		);

endmodule
