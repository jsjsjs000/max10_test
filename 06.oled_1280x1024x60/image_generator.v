`include "synthesis_directives.v"

module image_generator(
	input Clock,
	input Reset,
	output reg HS,
	output reg VS,
	output reg DE,
	output wire [7:0] R,
	output wire [7:0] G,
	output wire [7:0] B
);

 	reg [11:0] Hcounter = 12'd0;
 	reg [11:0] Vcounter = 12'd0;
 	reg [11:0] Pcounter = 12'd0;
 	reg Vactive = 1'b0;

	reg [3:0] ImageState = `INITIAL_IMAGE_STATE;		// state machine
	
	parameter IMAGE_COUNTER_MAX = 150;					// zmiana obrazu co 150 klatek - 2.5s (60kl/s)
	reg [7:0] ImageCounter = IMAGE_COUNTER_MAX;

	always @(posedge Clock, negedge Reset) begin
		if (!Reset) begin
			Hcounter <= `H_SYNC + `H_FRONT_PORCH + `WIDTH + `H_BACK_PORCH - 1;
			Vcounter <= `V_SYNC + `V_FRONT_PORCH + `HEIGHT - 1;
			Pcounter <= 12'hfff;
			Vactive <= 1'd0;
			HS <= `SYNC_L;
			VS <= `SYNC_L;
		end
		else begin
			Hcounter <= Hcounter + 1'b1;
			if (Hcounter == `H_SYNC - 1) begin
				HS <= `SYNC_L;					// end H_SYNC
			end
			else if (Vactive && (Hcounter == `H_SYNC + `H_FRONT_PORCH - 1 - 1)) begin
				Pcounter <= 12'd0;				// start of line
			end
			else if (Hcounter == `H_SYNC + `H_FRONT_PORCH + `WIDTH + `H_BACK_PORCH - 1) begin
												// end of line
				Vcounter <= Vcounter + 1'b1;
				if (Vcounter == `V_SYNC - 1) begin
					VS <= `SYNC_L;				// end V_SYNC
				end
				else if (Vcounter == `V_SYNC + `V_FRONT_PORCH - 1) begin
					Vactive <= 1'b1;			// start V_ACTIVE
				end
				else if (Vcounter == `V_SYNC + `V_FRONT_PORCH + `HEIGHT - 1) begin
					Vactive <= 1'b0;			// end V_ACTIVE
				end
				else if (Vcounter == `V_SYNC + `V_FRONT_PORCH + `HEIGHT + `V_BACK_PORCH - 1) begin
					Vcounter <= 0;				// end of frame
					VS <= `SYNC_H;

`ifdef CHANGE_IMAGE
					ImageCounter <= ImageCounter - 1'b1;
					if (ImageCounter - 1 == 0) begin
						ImageCounter <= IMAGE_COUNTER_MAX;

						case (ImageState)
							`IMAGE_STATE_RECTANGLE  : ImageState <= `IMAGE_STATE_V_BARS;
							`IMAGE_STATE_V_BARS     : ImageState <= `IMAGE_STATE_H_BARS;
							`IMAGE_STATE_H_BARS     : ImageState <= `IMAGE_STATE_GRAY_SCALE;
							`IMAGE_STATE_GRAY_SCALE : ImageState <= `IMAGE_STATE_RECTANGLE;
							default                 : ImageState <= `IMAGE_STATE_RECTANGLE;
						endcase
					end
`endif
				end

				Hcounter <= 12'd0;
				HS <= `SYNC_H;					// start H_SYNC
			end

			if (DE)								// active display
				Pcounter <= Pcounter + 1'd1;

			if (Vactive && (Hcounter == `H_SYNC + `H_FRONT_PORCH + `WIDTH - 2))
				Pcounter <= 12'hfff;			// end active display
		end
	end

	always @(negedge Clock, negedge Reset) begin
		if (!Reset) begin
			DE <= 1'b0;
		end
		else begin
			if (Vactive && (Hcounter == `H_SYNC + `H_FRONT_PORCH - 1)) begin
				DE <= 1'b1;					// start active display
			end
			else if (Vactive && (Hcounter == `H_SYNC + `H_FRONT_PORCH + `WIDTH - 1)) begin
				DE <= 1'b0;					// end active display
			end
		end
	end

	test_screens_generator test_screens_generator_impl(
		.Clock(Clock),
		.ImageState(ImageState),
		.x(Pcounter),
		.y(Vcounter - `V_SYNC - `V_FRONT_PORCH),
		.R(R),
		.G(G),
		.B(B),
		.DE(DE)
	);
endmodule
