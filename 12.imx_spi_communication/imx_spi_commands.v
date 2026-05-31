`default_nettype none

module max10_cmd_handler
(
	input	wire			req_valid,
	input	wire	[7:0]		req_cmd,
	input	wire	[7:0]		req_len,
	input	wire	[2039:0]	req_data_flat,

	input	wire	[7:0]		reg0_value,
	input	wire	[7:0]		reg1_value,

	output	reg			reg0_wr_en,
	output	reg			reg1_wr_en,
	output	reg	[7:0]		reg_wr_data,

	output	reg			rsp_valid,
	output	reg	[7:0]		rsp_len,
	output	reg	[2039:0]	rsp_data_flat
);

	localparam	[7:0]	CMD_WRITE_REG0		= 8'h20;
	localparam	[7:0]	CMD_WRITE_REG1		= 8'h21;
	localparam	[7:0]	CMD_READ_REG0		= 8'h30;
	localparam	[7:0]	CMD_READ_REG1		= 8'h31;

	localparam	[7:0]	STATUS_OK		= 8'h00;
	localparam	[7:0]	STATUS_ERR_LEN		= 8'hE2;
	localparam	[7:0]	STATUS_ERR_CMD		= 8'hF0;

	wire	[7:0]		req_data0;

	assign req_data0 = req_data_flat[7:0];

	always @*
	begin
		reg0_wr_en = 1'b0;
		reg1_wr_en = 1'b0;
		reg_wr_data = 8'h00;

		rsp_valid = 1'b0;
		rsp_len = 8'd1;
		rsp_data_flat = {2040{1'b0}};
		rsp_data_flat[7:0] = STATUS_ERR_CMD;

		if (req_valid == 1'b1)
		begin
			rsp_valid = 1'b1;

			case (req_cmd)
				CMD_WRITE_REG0:
				begin
					rsp_len = 8'd1;

					if (req_len == 8'd1)
					begin
						reg0_wr_en = 1'b1;
						reg_wr_data = req_data0;
						rsp_data_flat[7:0] = STATUS_OK;
					end
					else
					begin
						rsp_data_flat[7:0] = STATUS_ERR_LEN;
					end
				end

				CMD_WRITE_REG1:
				begin
					rsp_len = 8'd1;

					if (req_len == 8'd1)
					begin
						reg1_wr_en = 1'b1;
						reg_wr_data = req_data0;
						rsp_data_flat[7:0] = STATUS_OK;
					end
					else
					begin
						rsp_data_flat[7:0] = STATUS_ERR_LEN;
					end
				end

				CMD_READ_REG0:
				begin
					rsp_len = 8'd1;

					if (req_len == 8'd0)
					begin
						rsp_data_flat[7:0] = reg0_value;
					end
					else
					begin
						rsp_data_flat[7:0] = STATUS_ERR_LEN;
					end
				end

				CMD_READ_REG1:
				begin
					rsp_len = 8'd1;

					if (req_len == 8'd0)
					begin
						rsp_data_flat[7:0] = reg1_value;
					end
					else
					begin
						rsp_data_flat[7:0] = STATUS_ERR_LEN;
					end
				end

				default:
				begin
					rsp_len = 8'd1;
					rsp_data_flat[7:0] = STATUS_ERR_CMD;
				end
			endcase
		end
	end

endmodule

`default_nettype wire
