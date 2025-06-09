module ModMult(input clk,reset,
               input [15:0] A,B,
               input [15:0] q,
               output[15:0] C);

// --------------------------------------------------------------- connections
wire [31:0] P;

// --------------------------------------------------------------- modules
intMult im(clk,reset,A,B,P);
ModRed  mr(clk,reset,q,P,C);

endmodule