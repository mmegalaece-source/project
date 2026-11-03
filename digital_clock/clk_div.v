module clkdiv(
input clk,reset,
output reg tick,refstart);
reg [31:0]count;
reg [15:0]refcount;
always@(posedge clk)begin
if (reset)begin
tick <= 0;
count <= 0;
end
else if(count == 10)begin
tick <= 1;
count <= 0;
end

else begin
count <= count+1'b1;
tick <= 0;
end
end

always@(posedge clk)begin
if(reset)begin
refstart <= 0;
refcount <= 0;
end
else if(refcount == 5)begin
refstart <= 1;
refcount <= 0;
end
else begin
refcount <= refcount+1'b1;
refstart <= 0;
end
end
endmodule
