module dual_port_bram #(
    parameter ADDR_WIDTH = 17,
    parameter DATA_WIDTH = 16
)(
    // Write port
    input  wire                  clka,
    input  wire                  wea,
    input  wire [ADDR_WIDTH-1:0] addra,
    input  wire [DATA_WIDTH-1:0] dina,

    // Read port
    input  wire                  clkb,
    input  wire [ADDR_WIDTH-1:0] addrb,
    output reg  [DATA_WIDTH-1:0] doutb
);

    (* ram_style = "block" *)
    reg [DATA_WIDTH-1:0] mem [0:76799];

    // Write operation
    always @(posedge clka) begin
        if (wea && addra < 76800)
            mem[addra] <= dina;
    end

    // Synchronous read operation
    always @(posedge clkb) begin
        if (addrb < 76800)
            doutb <= mem[addrb];
    end

endmodule
