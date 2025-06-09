`timescale 1ns / 1ps

`define DATA_SIZE_ARB   16
`define RING_SIZE       1024
`define PE_NUMBER       8
`define RING_DEPTH      ($clog2(`RING_SIZE))
`define PE_DEPTH        ($clog2(`PE_NUMBER))

module NTT_tb();

parameter HP = 10;
parameter FP = (2*HP);

reg                       clk,reset;
reg                       load_w;
reg                       load_data;
reg                       start;
reg  [`DATA_SIZE_ARB-1:0] din;
wire                      done;
wire [`DATA_SIZE_ARB-1:0] dout;

// ---------------------------------------------------------------- CLK

always #HP clk = ~clk;

// ---------------------------------------------------------------- TXT data

reg [`DATA_SIZE_ARB-1:0] params    [0:7];
reg [`DATA_SIZE_ARB-1:0] w         [0:((((1<<(`RING_DEPTH-`PE_DEPTH))-1)+`PE_DEPTH)<<`PE_DEPTH)-1];
reg [`DATA_SIZE_ARB-1:0] winv      [0:((((1<<(`RING_DEPTH-`PE_DEPTH))-1)+`PE_DEPTH)<<`PE_DEPTH)-1];
reg [`DATA_SIZE_ARB-1:0] ntt_pin   [0:`RING_SIZE-1];
reg [`DATA_SIZE_ARB-1:0] ntt_pout  [0:`RING_SIZE-1];

initial begin
	// ntt
	$readmemh("test/PARAM.txt"    , params   );
	$readmemh("test/W.txt"        , w        );
	$readmemh("test/WINV.txt"     , winv     );
	$readmemh("test/NTT_DIN.txt"  , ntt_pin  );
	$readmemh("test/NTT_DOUT.txt" , ntt_pout );
end

// ---------------------------------------------------------------- TEST case

integer k;

initial begin: CLK_RESET_INIT
	// clk & reset (150 cc)
	clk       = 0;
	reset     = 0;

	#200;
	reset    = 1;
	#200;
	reset    = 0;
	#100;

	#1000;
end

initial begin: LOAD_DATA
    load_w    = 0;
    load_data = 0;
    start     = 0;
    din       = 0;

    #1500;

    // load w
    load_w = 1;
    #FP;
    load_w = 0;

	for(k=0; k<((((1<<(`RING_DEPTH-`PE_DEPTH))-1)+`PE_DEPTH)<<`PE_DEPTH); k=k+1) begin
		din = w[k];
		#FP;
	end
	for(k=0; k<((((1<<(`RING_DEPTH-`PE_DEPTH))-1)+`PE_DEPTH)<<`PE_DEPTH); k=k+1) begin
		din = winv[k];
		#FP;
	end
	din = params[1];
	#FP;
	din = params[6];
	#FP;

	#(5*FP);

	// ---------- load data (ntt)
	load_data = 1;
    #FP;
    load_data = 0;

	for(k=0; k<(`RING_SIZE); k=k+1) begin
		din = ntt_pin[k];
		#FP;
	end

	#(5*FP);

	// start (ntt)
	start = 1;
	#FP;
	start = 0;
	#FP;

	while(done == 0)
		#FP;
	#FP;

	#(FP*(`RING_SIZE+10));

end

// ---------------------------------------------------------------- TEST control

reg [`DATA_SIZE_ARB-1:0] ntt_nout  [0:`RING_SIZE-1];

integer m;
integer en;

initial begin: CHECK_RESULT
	en = 0;
    #1500;

	// wait result (ntt)
	while(done == 0)
		#FP;
	#FP;

	// Store output (ntt)
	for(m=0; m<(`RING_SIZE); m=m+1) begin
		ntt_nout[m] = dout;
		#FP;
	end

	#FP;

	// Compare output with expected result (ntt)
	for(m=0; m<(`RING_SIZE); m=m+1) begin
		if(ntt_nout[m] == ntt_pout[m]) begin
			en = en+1;
		end
		else begin
		    $display("NTT:  Index-%d -- Calculated:%h, Expected:%h",m,ntt_nout[m],ntt_pout[m]);
		end
	end

	#FP;

	if(en == (`RING_SIZE))
		$display("NTT:  Correct");
	else
		$display("NTT:  Incorrect");
	
	$display("NTT:  en-%d", en);
	$display("NTT:  Index-0 -- Calculated:%h, Expected:%h",ntt_nout[0],ntt_pout[0]);

	$stop();

end

// ---------------------------------------------------------------- UUT

NTT unit    (clk,reset,
             load_w,
             load_data,
             start,
             din,
             done,
             dout);

endmodule
