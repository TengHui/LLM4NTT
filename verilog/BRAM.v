module BRAM #(parameter DLEN = 32, HLEN=9)
           (input                 clk,
            input                 wen,
            input      [HLEN-1:0] waddr,
            input      [DLEN-1:0] din,
            input      [HLEN-1:0] raddr,
            output reg [DLEN-1:0] dout);
// bram
(* ram_style="block" *) reg [DLEN-1:0] blockram [(1<<HLEN)-1:0];

// write operation
always @(posedge clk) begin
    if(wen)
        blockram[waddr] <= din;
end

// read operation
always @(posedge clk) begin
    dout <= blockram[raddr];
end

endmodule