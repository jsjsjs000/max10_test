module top (
	input  wire clk,      // PIN_L3, 10 MHz
	input  wire rst_n,    // PIN_R15
	output reg  led0,     // PIN_M16
	output wire led1,     // PIN_N16
	output wire led2,     // PIN_P16
	output wire led3,     // PIN_R16
	output wire tmds_clk_p,         // PIN_T2
//	output wire tmds_clk_n,         // PIN_T3
	output wire [2:0] tmds_data_p   // 2:0: PIN_R5, PIN_R2, PIN_T4
//	output wire [2:0] tmds_data_n   // 2:0: PIN_R6, PIN_R3, PIN_T5
);

	localparam integer CLK_HZ = 25_000_000;
	localparam integer CNT_MAX = (CLK_HZ / 2) - 1;

		// PLL
	wire pllclock;
	wire pllclock_x5;
	wire locked;

	altpll_ip altpll_inst (
		.areset (~rst_n),
		.inclk0 (clk),
		.c0     (pllclock),     // 10*161/64=25,142857 MHz
		.c1     (pllclock_x5),  // 10*805/64=125,714286 MHz
		.locked (locked)
	);

		// HDMI generator
    wire [9:0] x, y;
    wire hsync, vsync, de;

    vga_640x480 vga (
        .clk(pllclock),
        .rst(~rst_n),
        .x(x),
		  .y(y),
        .hsync(hsync),
        .vsync(vsync),
        .de(de)
    );

    // ===== test pattern =====
reg [7:0] red_d, green_d, blue_d;
reg hsync_d, vsync_d;
reg de_d;

	reg [7:0] red, green, blue;
	wire [2:0] bar = x / 80;  // 0..7
	always @(posedge pllclock) begin
		de_d <= de;
		hsync_d <= hsync;
		vsync_d <= vsync;
		
		if (!de) begin
			red_d   = 8'h00;
			green_d = 8'h00;
			blue_d  = 8'h00;
		end else if (x == 0 || x == 640 - 1 || y == 0 || y == 480 - 1) begin
			red_d <= 8'hff; green_d <= 8'hff; blue_d <= 8'hff; // white rectangle
		end else begin
			case (bar)
				3'd0: begin red_d <= 8'hff; green_d <= 8'h00; blue_d <= 8'h00; end // white
				3'd1: begin red_d <= 8'h00; green_d <= 8'hff; blue_d <= 8'h00; end // yellow
				3'd2: begin red_d <= 8'h00; green_d <= 8'h00; blue_d <= 8'hff; end // cyan
				3'd3: begin red_d <= 8'hff; green_d <= 8'hff; blue_d <= 8'h00; end // green
				3'd4: begin red_d <= 8'h00; green_d <= 8'hff; blue_d <= 8'hff; end // magenta
				3'd5: begin red_d <= 8'hff; green_d <= 8'h00; blue_d <= 8'hff; end // red
				3'd6: begin red_d <= 8'hff; green_d <= 8'hff; blue_d <= 8'hff; end // blue
				default: begin red_d <= 8'h00; green_d <= 8'h00; blue_d <= 8'h00; end // black
			endcase
		end
	end

    // ===== TMDS =====
    wire [9:0] tmds_r, tmds_g, tmds_b;
    tmds_encoder enc_r(.clk(pllclock), .vd(red_d),   .cd(2'b00), .de(de_d), .q(tmds_r));
    tmds_encoder enc_g(.clk(pllclock), .vd(green_d), .cd(2'b00), .de(de_d), .q(tmds_g));
    tmds_encoder enc_b(.clk(pllclock), .vd(blue_d),  .cd({vsync_d, hsync_d}), .de(de_d), .q(tmds_b));

    // ===== LVDS serializer =====
	wire [29:0] tmds_bus;
	assign tmds_bus = {
		 tmds_r[0], tmds_r[1], tmds_r[2], tmds_r[3], tmds_r[4],
		 tmds_r[5], tmds_r[6], tmds_r[7], tmds_r[8], tmds_r[9],

		 tmds_g[0], tmds_g[1], tmds_g[2], tmds_g[3], tmds_g[4],
		 tmds_g[5], tmds_g[6], tmds_g[7], tmds_g[8], tmds_g[9],

		 tmds_b[0], tmds_b[1], tmds_b[2], tmds_b[3], tmds_b[4],
		 tmds_b[5], tmds_b[6], tmds_b[7], tmds_b[8], tmds_b[9]
	};

	 
    lvds_tx lvds (
        .tx_inclock(pllclock_x5),
        .tx_coreclock(pllclock),
        .tx_in(tmds_bus),
        .tx_out_p(tmds_data_p),
        .tx_out_n(tmds_data_n)
    );

    // ===== clock lane =====
    assign tmds_clk_p = pllclock;



	 
		// LED
	reg [26:0] counter;

	always @(posedge pllclock or negedge rst_n) begin
		if (!rst_n) begin
			counter <= 25'd0;
			led0     <= 1'b0;
		end else begin
			if (counter == CNT_MAX) begin
				counter <= 25'd0;
				led0    <= ~led0;
			end else begin
				counter <= counter + 1'b1;
			end
		end
	end

	assign led1 = 1'd1;
	assign led2 = 1'd1;
	assign led3 = 1'd1;

endmodule

/*
10M08DAF256C8GES
10 MHz
*/
