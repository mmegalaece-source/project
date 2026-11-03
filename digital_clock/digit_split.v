module digitsplit(
    input [5:0] min,
    input [5:0] sec,

    output reg [3:0] min_tens,
    output reg [3:0] min_ones,
    output reg [3:0] sec_tens,
    output reg [3:0] sec_ones
);

always @(*)
begin
    min_tens = min / 10;
    min_ones = min % 10;

    sec_tens = sec / 10;
    sec_ones = sec % 10;
end

endmodule
