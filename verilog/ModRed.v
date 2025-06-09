module ModRed (input                               clk,reset,
			   input      [15:0]                   q,
			   input      [31:0]                   P,
			   output reg [15:0]                   C);

// connections
wire [31:0] C_reg [2:0];

assign C_reg[0][31:0] = P[31:0];

// ------------------------------------------------------------- XY+Z+Cin operations (except for the last one)
genvar i_gen_loop;
generate
  for(i_gen_loop=0; i_gen_loop < 1; i_gen_loop=i_gen_loop+1)
  begin
		ModRed_sub     #(.CURR_DATA(32-(i_gen_loop)*10),
						 .NEXT_DATA(32-(i_gen_loop+1)*10))
		           mrs  (.clk(clk),
						 .reset(reset),
						 .qH(q[15:11]),
						 .T1(C_reg[i_gen_loop][(32-(i_gen_loop)*10)-1:0]),
						 .C (C_reg[i_gen_loop+1][(32-(i_gen_loop+1)*10)-1:0]));

  end
endgenerate

// ------------------------------------------------------------- XY+Z+Cin operations (the last one)
ModRed_sub     #(.CURR_DATA(22),
				 .NEXT_DATA(18))
		   mrsl (.clk(clk),
				 .reset(reset),
				 .qH(q[15:11]),
				 .T1(C_reg[1][21:0]),
				 .C (C_reg[2][17:0]));

// ------------------------------------------------------------- final subtraction
wire [17:0] C_ext;
wire [17:0] C_temp;

assign C_ext  = C_reg[2][17:0];
assign C_temp = C_ext - q;

// ------------------------------------------------------------- final comparison
always @(posedge clk or posedge reset)
begin
	if(reset) begin
		C <= 0;
	end
	else begin
		if (C_temp[17])
			C <= C_ext;
		else
			C <= C_temp[15:0];
	end
end

endmodule

module ModRed_sub #(parameter CURR_DATA = 0, NEXT_DATA = 0)
                  (input                                     clk,reset,
				   input     [4:0]                          qH,
				   input     [CURR_DATA-1:0]                 T1,
				   output reg[NEXT_DATA-1:0]                 C);

// connections
reg [10:0]                      T2L;
reg [10:0]                      T2;

reg [(CURR_DATA - 11)-1:0]      T2H;
reg                             CARRY;

(* use_dsp = "yes" *) reg [15:0]      MULT;

// --------------------------------------------------------------- multiplication of qH and T2 (and registers)
always @(*) begin
	T2L = T1[10:0];
    T2  = (-T2L);
end

always @(posedge clk or posedge reset) begin
    if(reset) begin
        T2H   <= 0;
        CARRY <= 0;
        MULT  <= 0;
    end
    else begin
        T2H   <= (T1 >> 11);
        CARRY <= (T2L[10] | T2[10]);
        MULT  <= qH * T2;
    end
end

// --------------------------------------------------------------- final addition operation
always @(posedge clk or posedge reset) begin
    if(reset) begin
        C <= 0;
    end
    else begin
        C <= (MULT+T2H)+CARRY;
    end
end

endmodule