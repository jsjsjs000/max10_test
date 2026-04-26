module tmds_encoder (
    input  wire       clk,
    input  wire [7:0] vd,     // video data
    input  wire [1:0] cd,     // control data (vsync, hsync)
    input  wire       de,     // data enable

    output reg  [9:0] q       // TMDS output
);

    integer i;

    reg [3:0] n1d;
    reg [8:0] q_m;
    reg signed [5:0] disparity = 0;

    // count ones in input
    always @(*) begin
        n1d = vd[0] + vd[1] + vd[2] + vd[3] +
              vd[4] + vd[5] + vd[6] + vd[7];
    end

    // stage 1: transition minimization
    always @(*) begin
        q_m[0] = vd[0];

        for (i = 1; i < 8; i = i + 1) begin
            if (n1d > 4 || (n1d == 4 && vd[0] == 0))
                q_m[i] = ~(q_m[i-1] ^ vd[i]);
            else
                q_m[i] =  (q_m[i-1] ^ vd[i]);
        end

        if (n1d > 4 || (n1d == 4 && vd[0] == 0))
            q_m[8] = 0;
        else
            q_m[8] = 1;
    end

    // count ones in q_m[7:0]
    wire signed [5:0] balance_m =
        (q_m[0] + q_m[1] + q_m[2] + q_m[3] +
         q_m[4] + q_m[5] + q_m[6] + q_m[7]) - 4;

    // stage 2: DC balancing
    always @(posedge clk) begin
        if (!de) begin
            // control symbols
            case (cd)
                2'b00: q <= 10'b1101010100;
                2'b01: q <= 10'b0010101011;
                2'b10: q <= 10'b0101010100;
                2'b11: q <= 10'b1010101011;
            endcase
            disparity <= 0;
        end else begin
            if (disparity == 0 || balance_m == 0) begin
                q <= {~q_m[8], q_m[8], q_m[7:0]};
                if (q_m[8] == 0)
                    disparity <= disparity + balance_m;
                else
                    disparity <= disparity - balance_m;
            end
            else if ((disparity > 0 && balance_m > 0) ||
                     (disparity < 0 && balance_m < 0)) begin
                q <= {1'b1, q_m[8], ~q_m[7:0]};
                if (q_m[8] == 0)
                    disparity <= disparity - balance_m;
                else
                    disparity <= disparity + balance_m;
            end
            else begin
                q <= {1'b0, q_m[8], q_m[7:0]};
                if (q_m[8] == 0)
                    disparity <= disparity + balance_m;
                else
                    disparity <= disparity - balance_m;
            end
        end
    end

endmodule