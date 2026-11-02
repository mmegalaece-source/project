`timescale 1ns / 1ps

module clk_gen (
    input  wire clk_in,
    input  wire reset,

    output wire pixel_clk,
    output wire pixel_clk_x5,
    output wire cam_xclk,

    output wire locked
);

    // Input clock buffer
    wire clk_in_buf;

    // MMCM feedback signals
    wire clkfb;
    wire clkfb_buf;

    // Internal MMCM output clocks
    wire clkout0;
    wire clkout1;
    wire clkout2;

    // Buffer input clock
    IBUF input_clk_buffer (
        .I(clk_in),
        .O(clk_in_buf)
    );

    // MMCM clock generation
    MMCME2_ADV #(
        .BANDWIDTH("OPTIMIZED"),

        // Input clock = 50 MHz
        .CLKIN1_PERIOD(20.000),

        // VCO calculation
        .DIVCLK_DIVIDE(1),
        .CLKFBOUT_MULT_F(12.500),

        // Output 0 = 25 MHz
        .CLKOUT0_DIVIDE_F(25.000),
        .CLKOUT0_DUTY_CYCLE(0.500),
        .CLKOUT0_PHASE(0.000),

        // Output 1 = 125 MHz
        .CLKOUT1_DIVIDE(5),
        .CLKOUT1_DUTY_CYCLE(0.500),
        .CLKOUT1_PHASE(0.000),

        // Output 2 = 24.03846 MHz
        .CLKOUT2_DIVIDE(26),
        .CLKOUT2_DUTY_CYCLE(0.500),
        .CLKOUT2_PHASE(0.000),

        .REF_JITTER1(0.010),
        .STARTUP_WAIT("FALSE")
    )
    mmcm_inst (
        .CLKIN1(clk_in_buf),
        .CLKIN2(1'b0),
        .CLKINSEL(1'b1),

        // Feedback
        .CLKFBIN(clkfb_buf),
        .CLKFBOUT(clkfb),

        // Clock outputs
        .CLKOUT0(clkout0),
        .CLKOUT1(clkout1),
        .CLKOUT2(clkout2),

        // Unused clock outputs
        .CLKOUT0B(),
        .CLKOUT1B(),
        .CLKOUT2B(),
        .CLKOUT3(),
        .CLKOUT3B(),
        .CLKOUT4(),
        .CLKOUT5(),
        .CLKOUT6(),

        // Control
        .PWRDWN(1'b0),
        .RST(reset),
        .LOCKED(locked)
    );

    // Feedback clock buffer
    BUFG feedback_buffer (
        .I(clkfb),
        .O(clkfb_buf)
    );

    // Pixel clock buffer: 25 MHz
    BUFG pixel_clock_buffer (
        .I(clkout0),
        .O(pixel_clk)
    );

    // Serializer clock buffer: 125 MHz
    BUFG serializer_clock_buffer (
        .I(clkout1),
        .O(pixel_clk_x5)
    );

    // Camera XCLK buffer: 24.03846 MHz
    BUFG camera_clock_buffer (
        .I(clkout2),
        .O(cam_xclk)
    );

endmodule
