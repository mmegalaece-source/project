module tmds_encoder (
    input  wire       clk,
    input  wire [7:0] data_in,
    input  wire [1:0] control_in,
    input  wire       video_active,
    output reg  [9:0] tmds_out
);

    wire [3:0] ones_count =
        {3'b0,data_in[0]} +
        {3'b0,data_in[1]} +
        {3'b0,data_in[2]} +
        {3'b0,data_in[3]} +
        {3'b0,data_in[4]} +
        {3'b0,data_in[5]} +
        {3'b0,data_in[6]} +
        {3'b0,data_in[7]};

    wire use_xnor;

    assign use_xnor =
        (ones_count > 4) ||
        ((ones_count == 4) && (data_in[0] == 1'b0));

    wire [8:0] q_m;

    assign q_m[0] = data_in[0]; 
    assign q_m[1] = use_xnor ? ~(q_m[0] ^ data_in[1]) : (q_m[0] ^ data_in[1]);
        assign q_m[2] = use_xnor ? ~(q_m[1] ^ data_in[2]) : (q_m[1] ^ data_in[2]);
        assign q_m[3] = use_xnor ? ~(q_m[2] ^ data_in[3]) : (q_m[2] ^ data_in[3]);
        assign q_m[4] = use_xnor ? ~(q_m[3] ^ data_in[4]) : (q_m[3] ^ data_in[4]);
        assign q_m[5] = use_xnor ? ~(q_m[4] ^ data_in[5]) : (q_m[4] ^ data_in[5]);
        assign q_m[6] = use_xnor ? ~(q_m[5] ^ data_in[6]) : (q_m[5] ^ data_in[6]);
        assign q_m[7] = use_xnor ? ~(q_m[6] ^ data_in[7]) : (q_m[6] ^ data_in[7]);
        assign q_m[8] = ~use_xnor;
    
        reg signed [7:0] disparity = 0;
        wire [3:0] ones_qm = q_m[0] + q_m[1] + q_m[2] + q_m[3] + q_m[4] + q_m[5] + q_m[6] + q_m[7];
        wire [3:0] zeros_qm = 8 - ones_qm;
    
        always @(posedge clk) begin
            if (!video_active) begin
                disparity <= 0;
               case (control_in)
    2'b00: tmds_out <= 10'b1101010100;
    2'b01: tmds_out <= 10'b0010101011;
    2'b10: tmds_out <= 10'b0101010100;
    2'b11: tmds_out <= 10'b1010101011;
endcase
	    end else begin
                if (disparity == 0 || ones_qm == zeros_qm) begin
                    tmds_out <= {~q_m[8], q_m[8], (q_m[8] ? q_m[7:0] : ~q_m[7:0])};
                    disparity <= (q_m[8] == 0) ? disparity + (zeros_qm - ones_qm) : disparity + (ones_qm - zeros_qm);
                end else if ((disparity > 0 && ones_qm > zeros_qm) || (disparity < 0 && zeros_qm > ones_qm)) begin
                    tmds_out <= {1'b1, q_m[8], ~q_m[7:0]};
                    disparity <= disparity + {q_m[8], 1'b0} + (zeros_qm - ones_qm);
                end else begin
                    tmds_out <= {1'b0, q_m[8], q_m[7:0]};
                    disparity <= disparity - {~q_m[8], 1'b0} + (ones_qm - zeros_qm);
                end
            end
        end
    endmodule

