// IBUF simulation model
module IBUF (
    input I,
    output O
);
    assign O = I;
endmodule

// BUFG simulation model
module BUFG (
    input I,
    output O
);
    assign O = I;
endmodule

// OBUFDS simulation model
module OBUFDS (
    input I,
    output O,
    output OB
);
    assign O = I;
    assign OB = ~I;
endmodule

// ODDR simulation model
module ODDR #(
    parameter DDR_CLK_EDGE = "OPPOSITE_EDGE",
    parameter INIT = 1'b0,
    parameter SRTYPE = "SYNC"
)(
    input C,
    input CE,
    input D1,
    input D2,
    input R,
    input S,
    output reg Q
);
    initial Q = INIT;

    always @(posedge C or posedge R or posedge S) begin
        if (R)
            Q <= 1'b0;
        else if (S)
            Q <= 1'b1;
        else if (CE)
            Q <= D1;
    end

    always @(negedge C) begin
        if (!R && !S && CE)
            Q <= D2;
    end
endmodule

// Simplified MMCM simulation model
module MMCME2_ADV #(
    parameter BANDWIDTH = "OPTIMIZED",
    parameter real CLKIN1_PERIOD = 10.0,
    parameter real CLKFBOUT_MULT_F = 5.0,
    parameter integer DIVCLK_DIVIDE = 1,
    parameter real CLKOUT0_DIVIDE_F = 1.0,
    parameter real CLKOUT0_DUTY_CYCLE = 0.5,
    parameter real CLKOUT0_PHASE = 0.0,
    parameter integer CLKOUT1_DIVIDE = 1,
    parameter real CLKOUT1_DUTY_CYCLE = 0.5,
    parameter real CLKOUT1_PHASE = 0.0,
    parameter integer CLKOUT2_DIVIDE = 1,
    parameter real CLKOUT2_DUTY_CYCLE = 0.5,
    parameter real CLKOUT2_PHASE = 0.0,
    parameter REF_JITTER1 = 0.010,
    parameter STARTUP_WAIT = "FALSE"
)(
    input CLKIN1, CLKIN2, CLKINSEL,
    input CLKFBIN,
    input RST, PWRDWN,
    input [6:0] DADDR,
    input DCLK, DEN, DWE,
    input [15:0] DI,
    input PSCLK, PSEN, PSINCDEC,

    output CLKFBOUT, CLKFBOUTB,
    output CLKOUT0, CLKOUT0B,
    output CLKOUT1, CLKOUT1B,
    output CLKOUT2, CLKOUT2B,
    output CLKOUT3, CLKOUT3B,
    output CLKOUT4, CLKOUT5, CLKOUT6,
    output LOCKED, PSDONE,
    output [15:0] DO,
    output DRDY
);

    assign CLKFBOUT = CLKIN1;
    assign CLKFBOUTB = ~CLKIN1;

    assign CLKOUT0 = CLKIN1;
    assign CLKOUT1 = CLKIN1;
    assign CLKOUT2 = CLKIN1;

    assign CLKOUT0B = ~CLKOUT0;
    assign CLKOUT1B = ~CLKOUT1;
    assign CLKOUT2B = ~CLKOUT2;

    assign CLKOUT3 = 1'b0;
    assign CLKOUT3B = 1'b1;
    assign CLKOUT4 = 1'b0;
    assign CLKOUT5 = 1'b0;
    assign CLKOUT6 = 1'b0;

    assign LOCKED = ~RST;
    assign PSDONE = 1'b0;
    assign DO = 16'b0;
    assign DRDY = 1'b0;

endmodule
