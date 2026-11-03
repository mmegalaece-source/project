module Topmodule(
    input clk,
    input reset,
    output [3:0] digit,
    output [6:0] seg
);
wire tick;
wire refstart;
wire [5:0] min;
wire [5:0] sec;
wire [3:0] mintens;
wire [3:0] minones;
wire [3:0] sectens;
wire [3:0] secones;
wire [6:0] seg_min_tens;
wire [6:0] seg_min_ones;
wire [6:0] seg_sec_tens;
wire [6:0] seg_sec_ones;
clkdiv u1 (
    .clk(clk),
    .reset(reset),
    .tick(tick),
    .refstart(refstart)
);
digital_clk u2 (
    .clk(clk),
    .reset(reset),
    .tick(tick),
    .min(min),
    .sec(sec)
);
digitsplit u3 (
    .min(min),
    .sec(sec),
    .min_tens(mintens),
    .min_ones(minones),
    .sec_tens(sectens),
    .sec_ones(secones)
);
sevenseg d1(.data(mintens),.seg(seg_min_tens));
sevenseg d2(.data(minones),.seg(seg_min_ones));
sevenseg d3(.data(sectens),.seg(seg_sec_tens));
sevenseg d4(.data(secones),.seg(seg_sec_ones));

mux u4 (
    .clk(clk),
    .reset(reset),
    .refstart(refstart),
    .seg_min_tens(seg_min_tens),
    .seg_min_once(seg_min_ones),
    .seg_sec_tens(seg_sec_tens),
    .seg_sec_once(seg_sec_ones),
    .seg(seg),
    .digit(digit)
);

endmodule
