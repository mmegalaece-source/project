module mux(
    input clk,
    input reset,
    input refstart,
    input [6:0] seg_sec_once,
    input [6:0] seg_sec_tens,
    input [6:0] seg_min_once,
    input [6:0] seg_min_tens,
    output reg [6:0] seg,
    output reg [3:0] digit
);
reg [1:0] digit_sel;
always @(posedge clk)
begin
    if (reset)
    begin
        digit_sel <= 0;
    end
    else if (refstart)
    begin
        digit_sel <= digit_sel + 1'b1;
    end
end
always @(*)
begin
    case (digit_sel)
        2'b00:
        begin
            digit = 4'b0001;
            seg = seg_min_tens;
        end

        2'b01:
        begin
            digit = 4'b0010;
            seg = seg_min_once;
        end

        2'b10:
        begin
            digit = 4'b0100;
            seg = seg_sec_tens;
        end

        2'b11:
        begin
            digit = 4'b1000;
            seg = seg_sec_once;
        end
        default:
        begin
            digit = 4'b1111;
            seg = 7'b1111111;
        end
    endcase
end
endmodule
