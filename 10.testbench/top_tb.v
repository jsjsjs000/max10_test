`timescale 1 ns/1 ps

module top_tb();
	reg clk = 1'b0;
	reg rst_n = 1'b1;
	wire hsync;
	wire vsync;
	wire de;

	always
	begin
		#5
		clk = ~clk;
	end

	top top_inst(
		.clk(clk),
		.rst_n(rst_n),
		.hsync(hsync),
		.vsync(vsync),
		.de(de)
	);

	initial begin
		$display("====== Start ======");
		#100_000_000;  // 100 ms
		$display("====== Stop ======");
		$stop;
	end
endmodule

/*
fix file:
C:\intelfpga_lite\22.1std\quartus\common\tcl\internal\nativelink\qnativelinkflow.tcl
	set questa_installation "$questa_fse_directory
to:
	set questa_installation "$questa_fse_directory"
*/
