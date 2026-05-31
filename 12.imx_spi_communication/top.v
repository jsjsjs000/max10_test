module top (
	input  wire clk,       // L3, 10 MHz
	input  wire rst_n,     // R15
	input  wire button1l,  // B16
	output wire led,       // M16

  //          GND               (devboard right4)
	input  wire m7_clk,    // C16 (devboard right5)
	input  wire m7_tx,     // C15 (devboard right6)
	output wire max10_tx   // D16 (devboard right7)
);

	assign led = clk & button1l;

	wire			req_valid;
	wire	[7:0]		req_cmd;
	wire	[7:0]		req_len;
	wire	[2039:0]	req_data_flat;

	wire			rsp_valid;
	wire	[7:0]		rsp_len;
	wire	[2039:0]	rsp_data_flat;

	wire			reg0_wr_en;
	wire			reg1_wr_en;
	wire	[7:0]		reg_wr_data;

	reg	[7:0]		reg0;
	reg	[7:0]		reg1;

//	assign dbg_reg0 = reg0;
//	assign dbg_reg1 = reg1;

	always @(posedge m7_clk or negedge rst_n)
	begin
		if (rst_n == 1'b0)
		begin
			reg0 <= 8'h00;
			reg1 <= 8'h00;
		end
		else
		begin
			if (reg0_wr_en == 1'b1)
			begin
				reg0 <= reg_wr_data;
			end

			if (reg1_wr_en == 1'b1)
			begin
				reg1 <= reg_wr_data;
			end
		end
	end

	max10_3wire_phy u_phy
	(
		.rst_n			(rst_n),

		.m7_clk			(m7_clk),
		.m7_tx			(m7_tx),
		.max10_tx		(max10_tx),

		.req_valid		(req_valid),
		.req_cmd		(req_cmd),
		.req_len		(req_len),
		.req_data_flat		(req_data_flat),

		.rsp_valid		(rsp_valid),
		.rsp_len		(rsp_len),
		.rsp_data_flat		(rsp_data_flat)
	);

	max10_cmd_handler u_cmd_handler
	(
		.req_valid		(req_valid),
		.req_cmd		(req_cmd),
		.req_len		(req_len),
		.req_data_flat		(req_data_flat),

		.reg0_value		(reg0),
		.reg1_value		(reg1),

		.reg0_wr_en		(reg0_wr_en),
		.reg1_wr_en		(reg1_wr_en),
		.reg_wr_data		(reg_wr_data),

		.rsp_valid		(rsp_valid),
		.rsp_len		(rsp_len),
		.rsp_data_flat		(rsp_data_flat)
	);



endmodule

/*
10M08DAF256C8GES
10 MHz
*/
