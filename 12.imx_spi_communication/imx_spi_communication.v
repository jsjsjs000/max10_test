`default_nettype none

module max10_3wire_phy
(
	input	wire			rst_n,

	input	wire			m7_clk,
	input	wire			m7_tx,
	output	reg			max10_tx,

	output	reg			req_valid,
	output	reg	[7:0]		req_cmd,
	output	reg	[7:0]		req_len,
	output	wire	[2039:0]	req_data_flat,

	input	wire			rsp_valid,
	input	wire	[7:0]		rsp_len,
	input	wire	[2039:0]	rsp_data_flat
);

	localparam	[7:0]	REQ_START_BYTE		= 8'hA5;
	localparam	[7:0]	RSP_START_BYTE		= 8'h5A;

	localparam	[2:0]	RX_WAIT_START		= 3'd0;
	localparam	[2:0]	RX_CMD			= 3'd1;
	localparam	[2:0]	RX_LEN			= 3'd2;
	localparam	[2:0]	RX_DATA			= 3'd3;
	localparam	[2:0]	RX_CRC			= 3'd4;

	reg	[2:0]		rx_state;
	reg	[2:0]		rx_bit_cnt;
	reg	[7:0]		rx_shift;
	reg	[7:0]		rx_index;
	reg	[7:0]		rx_crc_calc;

	reg	[7:0]		req_data_mem	[0:254];

	reg			tx_active;
	reg	[8:0]		tx_byte_pos;
	reg	[2:0]		tx_bit_pos;
	reg	[7:0]		tx_shift;

	reg	[7:0]		tx_len;
	reg	[7:0]		tx_crc;
	reg	[7:0]		tx_data_mem	[0:254];

	wire	[7:0]		rx_next_byte;
	wire	[8:0]		tx_last_byte_pos;
	wire	[8:0]		tx_next_byte_pos;

	reg	[7:0]		tx_next_byte;

	integer			i;

	genvar			g;

	assign rx_next_byte = {rx_shift[6:0], m7_tx};
	assign tx_last_byte_pos = {1'b0, tx_len} + 9'd2;
	assign tx_next_byte_pos = tx_byte_pos + 9'd1;

	generate
		for (g = 0; g < 255; g = g + 1)
		begin : gen_req_flat
			assign req_data_flat[(g * 8) +: 8] = req_data_mem[g];
		end
	endgenerate

	function [7:0] crc8_update;
		input	[7:0]	crc_in;
		input	[7:0]	data_in;

		integer		j;
		reg	[7:0]	c;

		begin
			c = crc_in ^ data_in;

			for (j = 0; j < 8; j = j + 1)
			begin
				if (c[7] == 1'b1)
				begin
					c = {c[6:0], 1'b0} ^ 8'h07;
				end
				else
				begin
					c = {c[6:0], 1'b0};
				end
			end

			crc8_update = c;
		end
	endfunction

	function [7:0] rsp_flat_byte;
		input	[2039:0]	flat;
		input	[7:0]		index;

		begin
			rsp_flat_byte = flat[(index * 8) +: 8];
		end
	endfunction

	always @*
	begin
		if (tx_next_byte_pos == 9'd1)
		begin
			tx_next_byte = tx_len;
		end
		else if ((tx_next_byte_pos >= 9'd2) && (tx_next_byte_pos < ({1'b0, tx_len} + 9'd2)))
		begin
			tx_next_byte = tx_data_mem[tx_next_byte_pos - 9'd2];
		end
		else
		begin
			tx_next_byte = tx_crc;
		end
	end

	always @(posedge m7_clk or negedge rst_n)
	begin
		if (rst_n == 1'b0)
		begin
			rx_state <= RX_WAIT_START;
			rx_bit_cnt <= 3'd0;
			rx_shift <= 8'h00;
			rx_index <= 8'h00;
			rx_crc_calc <= 8'h00;

			req_valid <= 1'b0;
			req_cmd <= 8'h00;
			req_len <= 8'h00;

			for (i = 0; i < 255; i = i + 1)
			begin
				req_data_mem[i] <= 8'h00;
			end
		end
		else
		begin
			req_valid <= 1'b0;
			rx_shift <= rx_next_byte;

			if (rx_bit_cnt != 3'd7)
			begin
				rx_bit_cnt <= rx_bit_cnt + 3'd1;
			end
			else
			begin
				rx_bit_cnt <= 3'd0;

				case (rx_state)
					RX_WAIT_START:
					begin
						rx_index <= 8'h00;
						rx_crc_calc <= 8'h00;

						if (rx_next_byte == REQ_START_BYTE)
						begin
							rx_state <= RX_CMD;
						end
						else
						begin
							rx_state <= RX_WAIT_START;
						end
					end

					RX_CMD:
					begin
						req_cmd <= rx_next_byte;
						rx_crc_calc <= crc8_update(8'h00, rx_next_byte);
						rx_state <= RX_LEN;
					end

					RX_LEN:
					begin
						req_len <= rx_next_byte;
						rx_index <= 8'h00;
						rx_crc_calc <= crc8_update(rx_crc_calc, rx_next_byte);

						if (rx_next_byte == 8'h00)
						begin
							rx_state <= RX_CRC;
						end
						else
						begin
							rx_state <= RX_DATA;
						end
					end

					RX_DATA:
					begin
						req_data_mem[rx_index] <= rx_next_byte;
						rx_crc_calc <= crc8_update(rx_crc_calc, rx_next_byte);

						if (rx_index == (req_len - 8'd1))
						begin
							rx_state <= RX_CRC;
						end
						else
						begin
							rx_index <= rx_index + 8'd1;
							rx_state <= RX_DATA;
						end
					end

					RX_CRC:
					begin
						if (rx_next_byte == rx_crc_calc)
						begin
							req_valid <= 1'b1;
						end

						rx_index <= 8'h00;
						rx_state <= RX_WAIT_START;
					end

					default:
					begin
						rx_index <= 8'h00;
						rx_state <= RX_WAIT_START;
					end
				endcase
			end
		end
	end

	function [7:0] crc8_response_calc;
		input	[7:0]		len;
		input	[2039:0]	flat;

		integer			k;
		reg	[7:0]		c;

		begin
			c = crc8_update(8'h00, len);

			for (k = 0; k < 255; k = k + 1)
			begin
				if (k < len)
				begin
					c = crc8_update(c, flat[(k * 8) +: 8]);
				end
			end

			crc8_response_calc = c;
		end
	endfunction

	always @(negedge m7_clk or negedge rst_n)
	begin
		if (rst_n == 1'b0)
		begin
			max10_tx <= 1'b1;

			tx_active <= 1'b0;
			tx_byte_pos <= 9'd0;
			tx_bit_pos <= 3'd7;
			tx_shift <= 8'hFF;
			tx_len <= 8'h00;
			tx_crc <= 8'h00;

			for (i = 0; i < 255; i = i + 1)
			begin
				tx_data_mem[i] <= 8'h00;
			end
		end
		else
		begin
			if ((tx_active == 1'b0) && (rsp_valid == 1'b1))
			begin
				tx_active <= 1'b1;
				tx_byte_pos <= 9'd0;
				tx_bit_pos <= 3'd7;
				tx_shift <= RSP_START_BYTE;
				max10_tx <= RSP_START_BYTE[7];

				tx_len <= rsp_len;
				tx_crc <= crc8_response_calc(rsp_len, rsp_data_flat);

				for (i = 0; i < 255; i = i + 1)
				begin
					tx_data_mem[i] <= rsp_flat_byte(rsp_data_flat, i);
				end
			end
			else if (tx_active == 1'b1)
			begin
				if (tx_bit_pos != 3'd0)
				begin
					tx_bit_pos <= tx_bit_pos - 3'd1;
					max10_tx <= tx_shift[tx_bit_pos - 3'd1];
				end
				else
				begin
					if (tx_byte_pos == tx_last_byte_pos)
					begin
						tx_active <= 1'b0;
						tx_byte_pos <= 9'd0;
						tx_bit_pos <= 3'd7;
						tx_shift <= 8'hFF;
						max10_tx <= 1'b1;
					end
					else
					begin
						tx_byte_pos <= tx_next_byte_pos;
						tx_bit_pos <= 3'd7;
						tx_shift <= tx_next_byte;
						max10_tx <= tx_next_byte[7];
					end
				end
			end
			else
			begin
				max10_tx <= 1'b1;
			end
		end
	end

endmodule

`default_nettype wire
