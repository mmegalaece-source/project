`timescale 1ns / 1ps

module sobel_edge_top (
    input  wire        sys_clk,
    input  wire        rst_btn,

    // OV5640 camera interface
    input  wire        cam_pclk,
    input  wire        cam_vsync,
    input  wire        cam_href,
    input  wire [7:0]  cam_data,

    output wire        cam_xclk,
    output wire        cam_scl,
    inout  wire        cam_sda,
    output wire        cam_rst_n,
    output wire        cam_pwdn,

    // HDMI interface
    output wire        hdmi_clk_p,
    output wire        hdmi_clk_n,
    output wire [2:0]  hdmi_tx_p,
    output wire [2:0]  hdmi_tx_n,

    // Status LEDs
    output wire [2:0]  led
);

    //========================================================
    // 1. CLOCK GENERATION
    //========================================================

    wire locked;
    wire clk_display;
    wire clk_serial;
    wire cam_xclk_gen;

    clk_gen u_clk_gen (
        .clk_in       (sys_clk),
        .reset        (rst_btn),
        .pixel_clk    (clk_display),
        .pixel_clk_x5 (clk_serial),
        .cam_xclk     (cam_xclk_gen),
        .locked       (locked)
    );
    assign cam_xclk = cam_xclk_gen;
    //========================================================
    // 2. SYSTEM RESET CONTROL
    //========================================================

    reg [15:0] reset_counter = 16'd0;
    reg sys_rst_n = 1'b0;
    always @(posedge clk_display or negedge locked) begin
        if (!locked) begin
            reset_counter <= 16'd0;
            sys_rst_n     <= 1'b0;
        end
        else if (rst_btn) begin
            reset_counter <= 16'd0;
            sys_rst_n     <= 1'b0;
        end

        else if (reset_counter != 16'hffff) begin
            reset_counter <= reset_counter + 1'b1;
            sys_rst_n     <= 1'b0;
        end
        else begin
            sys_rst_n <= 1'b1;
        end

    end

    assign cam_rst_n = sys_rst_n;

    // Assumes OV5640 PWDN is active-high.
    assign cam_pwdn = 1'b0;

    //========================================================
    // 3. CAMERA RESET SYNCHRONIZER
    //========================================================

    reg [1:0] cam_reset_sync = 2'b00;

    always @(posedge cam_pclk or negedge sys_rst_n) begin

        if (!sys_rst_n)
            cam_reset_sync <= 2'b00;

        else
            cam_reset_sync <= {
                cam_reset_sync[0],
                1'b1
            };

    end

    wire cam_logic_rst_n = cam_reset_sync[1];

    //========================================================
    // 4. OV5640 CAMERA INITIALIZATION
    //========================================================

    wire cam_init_done;

    ov5640_init u_cam_init (
        .clk   (clk_display),
        .rst_n (sys_rst_n),
        .scl   (cam_scl),
        .sda   (cam_sda),
        .done  (cam_init_done)
    );

    //========================================================
    // 5. CAMERA INITIALIZATION CDC
    //========================================================

    reg [1:0] cam_init_done_sync = 2'b00;
    always @(posedge cam_pclk or negedge sys_rst_n) begin
        if (!sys_rst_n)
            cam_init_done_sync <= 2'b00;

        else
            cam_init_done_sync <= {
                cam_init_done_sync[0],
                cam_init_done
            };

    end
    wire camera_initialized = cam_init_done_sync[1];

    //========================================================
    // 6. OV5640 PIXEL CAPTURE
    //========================================================

    wire        camera_pixel_valid;
    wire [16:0] camera_pixel_addr;
    wire [15:0] camera_pixel_rgb565;

    ov5640_capture u_capture (
        .pclk      (cam_pclk),
        .rst_n     (cam_logic_rst_n),
        .cam_vsync (cam_vsync),
        .cam_href  (cam_href),
        .cam_data  (cam_data),
        .bram_we   (camera_pixel_valid),
        .bram_addr (camera_pixel_addr),
        .bram_din  (camera_pixel_rgb565)

    );

    //========================================================
    // 7. SOBEL EDGE DETECTION
    //========================================================
    wire        edge_we;
    wire [16:0] edge_wr_addr;
    wire [7:0]  edge_wr_data;
    wire edge_frame_ready_cam;
    // Enable processing only after camera initialization.
    wire sobel_pixel_valid =
        camera_pixel_valid && camera_initialized;
    sobel_stream_320 #(
        .WIDTH     (320),
        .HEIGHT    (240),
        .THRESHOLD (120)
    ) u_sobel (
        .pclk        (cam_pclk),
        .rst_n       (cam_logic_rst_n),
        .frame_sync  (cam_vsync),
        .pixel_valid (sobel_pixel_valid),
        .rgb565      (camera_pixel_rgb565),
        .edge_we     (edge_we),
        .edge_addr   (edge_wr_addr),
        .edge_data   (edge_wr_data),
        .frame_ready (edge_frame_ready_cam)

    );

    //========================================================
    // 8. DUAL-PORT EDGE BRAM
    //========================================================

    wire [16:0] display_addr;
    wire [7:0]  edge_rd_data;

    dual_port_bram #(
        .ADDR_WIDTH (17),
        .DATA_WIDTH (8)
    ) u_edge_ram (

        // Camera clock: Write operation
        .clka  (cam_pclk),
        .wea   (edge_we),
        .addra (edge_wr_addr),
        .dina  (edge_wr_data),

        // Display clock: Read operation
        .clkb  (clk_display),
        .addrb (display_addr),
        .doutb (edge_rd_data)
    );

    //========================================================
    // 9. FRAME READY SYNCHRONIZER
    //========================================================

    reg [1:0] frame_ready_sync = 2'b00;
    always @(posedge clk_display) begin
        if (!sys_rst_n)
            frame_ready_sync <= 2'b00;
        else
            frame_ready_sync <= {
                frame_ready_sync[0],
                edge_frame_ready_cam
            };

    end
    wire show_edges = frame_ready_sync[1];

    //========================================================
    // 10. VGA TIMING GENERATOR
    //========================================================

    wire hsync;
    wire vsync;
    wire video_active;
    wire [9:0] display_x;
    wire [9:0] display_y;

    vga_timing u_video_timing (
        .pixel_clk    (clk_display),
        .rst_n        (sys_rst_n),
        .bram_addr    (display_addr),
        .hsync        (hsync),
        .vsync        (vsync),
        .video_active (video_active),
        .pixel_x      (display_x),
        .pixel_y      (display_y)

    );

    //========================================================
    // 11. HDMI TEST COLOUR BARS
    //========================================================

    wire [7:0] bar_r;
    wire [7:0] bar_g;
    wire [7:0] bar_b;

    assign bar_r =
        ((display_x < 80) ||
         ((display_x >= 320) && (display_x < 480)))
        ? 8'hff : 8'h00;

    assign bar_g =
        ((display_x < 240) ||
         ((display_x >= 320) && (display_x < 400)))
        ? 8'hff : 8'h00;

    assign bar_b =
        ((display_x < 80) ||
         ((display_x >= 160) && (display_x < 320)))
        ? 8'hff : 8'h00;

    //========================================================
    // 12. VIDEO SOURCE SELECTION
    //========================================================

    wire [7:0] video_r;
    wire [7:0] video_g;
    wire [7:0] video_b;

    assign video_r = show_edges ? edge_rd_data : bar_r;
    assign video_g = show_edges ? edge_rd_data : bar_g;
    assign video_b = show_edges ? edge_rd_data : bar_b;

    //========================================================
    // 13. HDMI TRANSMITTER
    //========================================================

    hdmi_tx u_hdmi (
        .pixel_clk    (clk_display),
        .pixel_clk_x5 (clk_serial),
        .rst_n        (sys_rst_n),
        .red          (video_r),
        .green        (video_g),
        .blue         (video_b),
        .hsync        (hsync),
        .vsync        (vsync),
        .active       (video_active),
        .tmds_clk_p   (hdmi_clk_p),
        .tmds_clk_n   (hdmi_clk_n),
        .tmds_data_p  (hdmi_tx_p),
        .tmds_data_n  (hdmi_tx_n)
    );

    //========================================================
    // 14. STATUS LEDS
    //========================================================

    assign led[0] = cam_init_done;
    assign led[1] = show_edges;
    assign led[2] = locked;

endmodule
