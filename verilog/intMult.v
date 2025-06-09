module intMult(input clk,reset,
			   input [15:0] A,B,
			   output reg[31:0] C);

always @(posedge clk or posedge reset) begin
	if(reset)
		C <= 0;
	else
		C <= A * B;
end

endmodule