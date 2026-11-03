module digital_clk(input clk,reset,tick,output reg [5:0]sec,min);

always@(posedge clk or posedge reset)
begin
if(reset)begin
sec<=0;
min<=0;
end
else if(tick)begin
if(sec==59)begin
sec<=0;
if(min == 59)
min<=0;
else 
min<=min+1'b1;
end
else begin
sec<=sec+1'b1;
end
end
end
endmodule
