module NTT    (input                           clk,reset,
               input                           load_w,
               input                           load_data,
               input                           start,
               input [15:0]                    din,
               output reg                      done,
               output reg [15:0]               dout
               );
// ---------------------------------------------------------------- connections

// parameters & control
reg [2:0] state;
// 0: IDLE
// 1: load twiddle factors + q + n_inv
// 2: load data
// 3: performs ntt
// 4: output data

reg [13:0] sys_cntr;

reg [15:0] q;
reg [15:0] n_inv;

// data tw brams (datain,dataout,waddr,raddr,wen)
reg [15:0]        pi [15:0];
wire[15:0]        po [15:0];
reg [8:0]         pw [15:0];
reg [8:0]         pr [15:0];
reg [0:0]         pe [15:0];

reg [15:0]        ti [7:0];
wire[15:0]        to [7:0];
reg [10:0]        tw [7:0];
reg [10:0]        tr [7:0];
reg [0:0]         te [7:0];

// control signals
wire [8:0]        raddr;
wire [8:0]        waddr0,waddr1;
wire              wen0  ,wen1  ;
wire              brsel0,brsel1;
wire              brselen0,brselen1;
wire [63:0]       brscramble;
wire [9:0]        raddr_tw;

wire [4:0]        stage_count;
wire              ntt_finished;

// pu
reg [15:0] NTTin [15:0];
reg [15:0] MULin [7:0];
wire[15:0] ASout [15:0]; // ADD-SUB out  (no extra delay after odd)
wire[15:0] EOout [15:0]; // EVEN-ODD out

// ---------------------------------------------------------------- BRAMs
// 2*PE BRAMs for input-output polynomial
// PE BRAMs for storing twiddle factors

generate
	genvar k;

    for(k=0; k<8 ;k=k+1) begin: BRAM_GEN_BLOCK
        BRAM #(.DLEN(16),.HLEN(9)) bd00(clk,pe[2*k+0],pw[2*k+0],pi[2*k+0],pr[2*k+0],po[2*k+0]);
        BRAM #(.DLEN(16),.HLEN(9)) bd01(clk,pe[2*k+1],pw[2*k+1],pi[2*k+1],pr[2*k+1],po[2*k+1]);
        BRAM #(.DLEN(16),.HLEN(11)) bt00(clk,te[k],tw[k],ti[k],tr[k],to[k]);
    end
endgenerate

// ---------------------------------------------------------------- NTT2 units

generate
	genvar m;

    for(m=0; m<8 ;m=m+1) begin: NTT2_GEN_BLOCK
        // output declaration of module ButterFly
        reg [15:0] ADDout;
        wire SUBout;
        reg [15:0] NTToutEVEN;
        wire NTToutODD;
        ButterFly nttu(clk,reset,
                  q,
			      NTTin[2*m+0],NTTin[2*m+1],
				  MULin[m],
				  ASout[2*m+0],ASout[2*m+1],
				  EOout[2*m+0],EOout[2*m+1]);
    end
endgenerate

// ---------------------------------------------------------------- control unit

AddressGenerator ag(clk,reset,
                    start,
                    raddr,
                    waddr0,waddr1,
                    wen0  ,wen1  ,
                    brsel0,brsel1,
                    brselen0,brselen1,
                    brscramble,
                    raddr_tw,
                    stage_count,
                    ntt_finished
                    );

// ---------------------------------------------------------------- state machine & sys_cntr

always @(posedge clk or posedge reset) begin
    if(reset) begin
        state <= 3'd0;
        sys_cntr <= 0;
    end
    else begin
        case(state)
        3'd0: begin
            if(load_w)
                state <= 3'd1;
            else if(load_data)
                state <= 3'd2;
            else if(start)
                state <= 3'd3;
            else
                state <= 3'd0;
            sys_cntr <= 0;
        end
        3'd1: begin
            if(sys_cntr == ((((((1<<7)-1)+3)<<3)<<1)+2-1)) begin
                state <= 3'd0;
                sys_cntr <= 0;
            end
            else begin
                state <= 3'd1;
                sys_cntr <= sys_cntr + 1;
            end
        end
        3'd2: begin
            if(sys_cntr == 1023) begin
                state <= 3'd0;
                sys_cntr <= 0;
            end
            else begin
                state <= 3'd2;
                sys_cntr <= sys_cntr + 1;
            end
        end
        3'd3: begin
            if(ntt_finished)
                state <= 3'd4;
            else
                state <= 3'd3;
            sys_cntr <= 0;
        end
        3'd4: begin
            if(sys_cntr == 1025) begin
                state <= 3'd0;
                sys_cntr <= 0;
            end
            else begin
                state <= 3'd4;
                sys_cntr <= sys_cntr + 1;
            end
        end
        default: begin
            state <= 3'd0;
            sys_cntr <= 0;
        end
        endcase
    end
end

// ---------------------------------------------------------------- load twiddle factor + q + n_inv & other operations

always @(posedge clk or posedge reset) begin: TW_BLOCK
    integer n;
    for(n=0; n < 8; n=n+1) begin: LOOP_1
        if(reset) begin
            te[n] <= 0;
            tw[n] <= 0;
            ti[n] <= 0;
            tr[n] <= 0;
        end
        else begin
            if((state == 3'd1) && (sys_cntr < (((1<<7)-1)+3)<<3)) begin
                te[n] <= (n == (sys_cntr & 7));
                tw[n][10]   <= 0;
                tw[n][9:0] <= (sys_cntr >> 3);
                ti[n] <= din;
                tr[n] <= 0;
            end
            else if((state == 3'd1) && (sys_cntr < ((((1<<7)-1)+3)<<3)<<1)) begin
                te[n] <= (n == ((sys_cntr-((((1<<7)-1)+3)<<3)) & 7));
                tw[n][10]   <= 1;
                tw[n][9:0] <= ((sys_cntr-((((1<<7)-1)+3)<<3)) >> 3);
                ti[n] <= din;
                tr[n] <= 0;
            end
            else if(state == 3'd3) begin // NTT operations
                te[n] <= 0;
                tw[n] <= 0;
                ti[n] <= 0;
                tr[n] <= {1'b0,raddr_tw};
            end
            else begin
                te[n] <= 0;
                tw[n] <= 0;
                ti[n] <= 0;
                tr[n] <= 0;
            end
        end
    end
end

always @(posedge clk or posedge reset) begin
    if(reset) begin
        q     <= 0;
        n_inv <= 0;
    end
    else begin
        q     <= ((state == 3'd1) && (sys_cntr == ((((((1<<7)-1)+3)<<3)<<1)+2-2))) ? din : q;
        n_inv <= ((state == 3'd1) && (sys_cntr == ((((((1<<7)-1)+3)<<3)<<1)+2-1))) ? din : n_inv;
    end
end

// ---------------------------------------------------------------- load data & other data operations

wire [6:0] addrout;
assign addrout = (sys_cntr >> 4);

always @(posedge clk or posedge reset) begin: DT_BLOCK
    integer n;
    for(n=0; n < 16; n=n+1) begin: LOOP_1
        if(reset) begin
            pe[n] <= 0;
            pw[n] <= 0;
            pi[n] <= 0;
            pr[n] <= 0;
        end
        else begin
            if((state == 3'd2)) begin // input data
                if(sys_cntr < 512) begin
                    pe[n] <= (n == ((sys_cntr & 7) << 1));
                    pw[n] <= (sys_cntr >> 3);
                    pi[n] <= din;
                    pr[n] <= 0;
                end
                else begin
                    pe[n] <= (n == (((sys_cntr & 7) << 1)+1));
                    pw[n] <= ((sys_cntr-512) >> 3);
                    pi[n] <= din;
                    pr[n] <= 0;
                end
            end
            else if(state == 3'd3) begin // NTT operations
                if(stage_count < 6) begin
                    if(brselen0) begin
                        if(brsel0 == 0) begin
                            if(n[0] == 0) begin
                                pe[n] <= wen0;
                                pw[n] <= waddr0;
                                pi[n] <= EOout[n];
                            end
                        end
                        else begin // brsel0 == 1
                            if(n[0] == 0) begin
                                pe[n] <= wen1;
                                pw[n] <= waddr1;
                                pi[n] <= EOout[n+1];
                            end
                        end
                    end
                    else begin
                        if(n[0] == 0) begin
                            pe[n] <= 0;
                            pw[n] <= pw[n];
                            pi[n] <= pi[n];
                        end
                    end

                    if(brselen1) begin
                        if(brsel1 == 0) begin
                            if(n[0] == 1) begin
                                pe[n] <= wen0;
                                pw[n] <= waddr0;
                                pi[n] <= EOout[n-1];
                            end
                        end
                        else begin // brsel1 == 1
                            if(n[0] == 1) begin
                                pe[n] <= wen1;
                                pw[n] <= waddr1;
                                pi[n] <= EOout[n];
                            end
                        end
                    end
                    else begin
                        if(n[0] == 1) begin
                            pe[n] <= 0;
                            pw[n] <= pw[n];
                            pi[n] <= pi[n];
                        end
                    end
                end
                else if(stage_count < 9) begin
                    pe[n] <= wen0;
                    pw[n] <= waddr0;
                    pi[n] <= ASout[brscramble[4*n+:4]];
                end
                else begin
                    pe[n] <= wen0;
                    pw[n] <= waddr0;
                    pi[n] <= ASout[n];
                end
                pr[n] <= raddr;
            end
            else if(state == 3'd4) begin // output data
                pe[n] <= 0;
                pw[n] <= 0;
                pi[n] <= 0;
                pr[n] <= {2'b10,addrout};
            end
            else begin
                pe[n] <= 0;
                pw[n] <= 0;
                pi[n] <= 0;
                pr[n] <= 0;
            end
        end
    end
end

// done signal & output data
wire [3:0] coefout;
assign coefout = (sys_cntr-2);

always @(posedge clk or posedge reset) begin
    if(reset) begin
        done <= 0;
        dout <= 0;
    end
    else begin
        if(state == 3'd4) begin
            done <= (sys_cntr == 1) ? 1 : 0;
            dout <= po[coefout];
        end
        else begin
            done <= 0;
            dout <= 0;
        end
    end
end

// ---------------------------------------------------------------- PU control

always @(posedge clk or posedge reset) begin: NT_BLOCK
    integer n;
    for(n=0; n < 8; n=n+1) begin: LOOP_1
        if(reset) begin
            NTTin[2*n+0] <= 0;
            NTTin[2*n+1] <= 0;
            MULin[n] <= 0;
        end
        else begin
            NTTin[2*n+0] <= po[2*n+0];
            NTTin[2*n+1] <= po[2*n+1];
            MULin[n] <= to[n];
        end
    end
end

endmodule
