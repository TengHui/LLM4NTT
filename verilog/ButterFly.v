module ButterFly(input 					    clk,reset,
			input      [15:0]               q,
            input      [15:0]               NTTin0,NTTin1,
			input      [15:0]               MULin,
			output reg [15:0]               ADDout,SUBout,
			output reg [15:0]               NTToutEVEN,NTToutODD);

// modular add
wire        [16:0]                        madd;
wire signed [17:0]                        madd_q;
wire        [15:0]                        madd_res;

assign madd     = NTTin0 + NTTin1;
assign madd_q   = madd - q;
assign madd_res = (madd_q[17] == 1'b0) ? madd_q[15:0] : madd[15:0];

// modular sub
wire        [16:0]                        msub;
wire signed [17:0]                        msub_q;
wire        [15:0]                        msub_res;

assign msub     = NTTin0 - NTTin1;
assign msub_q   = msub + q;
assign msub_res = (msub[16] == 1'b0) ? msub[15:0] : msub_q[15:0];

// first level registers
reg [15:0] MULin0,MULin1;
reg [15:0] ADDreg;

always @(posedge clk) begin
	if(reset) begin
		MULin0 <= 0;
		MULin1 <= 0;
		ADDreg <= 0;
	end
	else begin
		MULin0 <= MULin;
		MULin1 <= msub_res;
		ADDreg <= madd_res;
	end
end

// modular mul
wire [15:0] MODout;
ModMult mm(clk,reset,MULin0,MULin1,q,MODout);

wire [15:0] ADDreg_next;
ShiftReg #(.SHIFT(6),.DATA(16)) unit00(clk,reset,ADDreg,ADDreg_next);

always @(*) begin
    ADDout = ADDreg_next;
    SUBout = MODout;

    NTToutEVEN = ADDreg_next;
end

// second level registers (output)
always @(posedge clk) begin
	if(reset) begin
		NTToutODD <= 0;
	end
	else begin
		NTToutODD <= SUBout;
	end
end

endmodule