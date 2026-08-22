module decomp (
    // Clock / Reset
    input  logic clk,
    input  logic rst,

    // Control flags
    input  logic go,
    output logic done,

    // M block
    input  logic [511:0] m_block,

    // W memory interface
    output logic [5:0]  wmem_addr,
    input  logic [31:0] wmem_rdata,
    output logic [31:0] wmem_wdata,
    output logic        wmem_en,
    output logic        wmem_we
);

//------------------------------------------------------------------------------
// FSM Control logic
//------------------------------------------------------------------------------

// State encodings
typedef enum logic [2:0] {
    StIdle,
    StWrite,
    StRead1,
    StRead2,
    StRead3,
    StRead4,
    StStall,
    StDone
} state_t;

// State registers
state_t state_d, state_q, state_q2;
logic [5:0] count_d, count_q;

// State transition logic
always_ff @(posedge clk) begin
    if (rst) begin
        state_q  <= StIdle;
        state_q2 <= StIdle;
        count_q  <= '0;
    end else begin
        state_q  <= state_d;
        state_q2 <= state_q;
        count_q  <= count_d;
    end
end

// Next state logic
always_comb begin
    // State transitions
    unique case (state_q)
        StIdle:  state_d = (go) ? StWrite : StIdle;
        StWrite: state_d = (count_q < 15) ? StWrite : (count_q == 63) ? StDone : StRead1;
        StRead1: state_d = StRead2;
        StRead2: state_d = StRead3;
        StRead3: state_d = StRead4;
        StRead4: state_d = StStall;
        StStall: state_d = StWrite;
        StDone:  state_d = StIdle;
    endcase

    // Counter to track W index
    unique case (state_q)
        StIdle:  count_d = '0;
        StWrite: count_d = count_q + 1'b1;
        StRead1: count_d = count_q;
        StRead2: count_d = count_q;
        StRead3: count_d = count_q;
        StRead4: count_d = count_q;
        StStall: count_d = count_q;
        StDone:  count_d = '0;
    endcase
end

//------------------------------------------------------------------------------
// Output logic
//------------------------------------------------------------------------------

logic [31:0] w2, w7, w15, w16;
logic [31:0] s0;
logic [31:0] s1;

lower_sigma sigma (
    .w0(w15),
    .w1(w2),
    .s0(s0),
    .s1(s1)
);

always_comb begin
    case (state_q)
        StRead1: wmem_addr = count_q - 2;
        StRead2: wmem_addr = count_q - 7;
        StRead3: wmem_addr = count_q - 15;
        StRead4: wmem_addr = count_q - 16;
        default: wmem_addr = count_q;
    endcase
end

always_comb begin
    // Values 0-15 are copied from M block
    if (count_q < 16) begin
        unique case (count_q[3:0])
            4'd0:  wmem_wdata = m_block[480+:32];
            4'd1:  wmem_wdata = m_block[448+:32];
            4'd2:  wmem_wdata = m_block[416+:32];
            4'd3:  wmem_wdata = m_block[384+:32];
            4'd4:  wmem_wdata = m_block[352+:32];
            4'd5:  wmem_wdata = m_block[320+:32];
            4'd6:  wmem_wdata = m_block[288+:32];
            4'd7:  wmem_wdata = m_block[256+:32];
            4'd8:  wmem_wdata = m_block[224+:32];
            4'd9:  wmem_wdata = m_block[192+:32];
            4'd10: wmem_wdata = m_block[160+:32];
            4'd11: wmem_wdata = m_block[128+:32];
            4'd12: wmem_wdata = m_block[96+:32];
            4'd13: wmem_wdata = m_block[64+:32];
            4'd14: wmem_wdata = m_block[32+:32];
            4'd15: wmem_wdata = m_block[0+:32];
        endcase
    end

    // Values 16-63 are computed using previous values
    else begin
        wmem_wdata = w16 + s0 + w7 + s1;
    end
end

always_comb begin
    case (state_q)
        StWrite: wmem_en = 1'b1;
        StRead1: wmem_en = 1'b1;
        StRead2: wmem_en = 1'b1;
        StRead3: wmem_en = 1'b1;
        StRead4: wmem_en = 1'b1;
        default: wmem_en = 1'b0;
    endcase
end

assign wmem_we = (state_q == StWrite);

always_ff @(posedge clk) begin
    if (state_q2 == StRead1) w2  <= wmem_rdata;
    if (state_q2 == StRead2) w7  <= wmem_rdata;
    if (state_q2 == StRead3) w15 <= wmem_rdata;
    if (state_q2 == StRead4) w16 <= wmem_rdata;
end

assign done = (state_q2 == StDone);

endmodule
