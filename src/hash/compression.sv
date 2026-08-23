module compression (
    // Clock / Reset
    input  logic clk,
    input  logic rst,

    // Control flags
    input  logic go,
    output logic done,

    // W memory interface
    output logic [5:0]  wmem_addr,
    output logic [31:0] wmem_din,
    input  logic [31:0] wmem_dout,
    output logic        wmem_en,
    output logic        wmem_we,

    // H memory interface
    output logic [2:0]  hmem_addr,
    input  logic [31:0] hmem_data,
    output logic        hmem_en,
    output logic        hmem_we,

    // K memory interface
    output logic [5:0]  kmem_addr,
    input  logic [31:0] kmem_data,
    output logic        kmem_en,
    output logic        kmem_we,

    // Message chunk
    input  logic [511:0] msg_chunk,

    // Computed hash
    output logic [255:0] hash
);

//------------------------------------------------------------------------------
// FSM Control
//------------------------------------------------------------------------------

// State encodings
typedef enum logic [2:0] {
    StIdle,
    StWord,
    StInit,
    StLoop,
    StHash,
    StDone
} state_t;

// State registers
state_t state_d, state_q, state_q2;
logic [5:0] count_d, count_q, count_q2;

// State transition logic
always_ff @(posedge clk) begin
    if (rst) begin
        state_q  <= StIdle;
        state_q2 <= StIdle;
        count_q  <= '0;
        count_q2 <= '0;
    end else begin
        state_q  <= state_d;
        state_q2 <= state_q;
        count_q  <= count_d;
        count_q2 <= count_q;
    end
end

// Next state logic
always_comb begin
    // State transitions
    case (state_q)
        StIdle:  state_d = (go) ? StWord : StIdle;
        StWord:  state_d = (count_q == 63) ? StInit : StWord;
        StInit:  state_d = (count_q == 7) ? StLoop : StInit;
        StLoop:  state_d = (count_q == 63) ? StHash : StLoop;
        StHash:  state_d = (count_q == 7) ? StDone : StHash;
        StDone:  state_d = StIdle;
        default: state_d = StIdle;
    endcase

    // Counter to track loop index
    case (state_q)
        StIdle:  count_d = '0;
        StWord:  count_d = (count_q + 1'b1);
        StInit:  count_d = (count_q + 1'b1) % 8;
        StLoop:  count_d = (count_q + 1'b1);
        StHash:  count_d = (count_q + 1'b1) % 8;
        StDone:  count_d = '0;
        default: count_d = '0;
    endcase
end

//------------------------------------------------------------------------------
// Datapath
//------------------------------------------------------------------------------

// Message scheduling
logic [31:0] w2, w7, w15, w16;
logic [31:0] s0l, s1l;

delay #(
    .WIDTH(32),
    .DEPTH(2)
) delay2 (
    .clk(clk),
    .din(wmem_din),
    .dout(w2)
);

delay #(
    .WIDTH(32),
    .DEPTH(7)
) delay7 (
    .clk(clk),
    .din(wmem_din),
    .dout(w7)
);

delay #(
    .WIDTH(32),
    .DEPTH(15)
) delay15 (
    .clk(clk),
    .din(wmem_din),
    .dout(w15)
);

delay #(
    .WIDTH(32),
    .DEPTH(16)
) delay16 (
    .clk(clk),
    .din(wmem_din),
    .dout(w16)
);

lower_sigma lower_sigma (
    .w0(w15),
    .w1(w2),
    .s0(s0l),
    .s1(s1l)
);

always_comb begin
    // Values 0-15 are copied from M block
    if (count_q < 16) begin
        unique case (count_q[3:0])
            4'd0:  wmem_din = msg_chunk[480+:32];
            4'd1:  wmem_din = msg_chunk[448+:32];
            4'd2:  wmem_din = msg_chunk[416+:32];
            4'd3:  wmem_din = msg_chunk[384+:32];
            4'd4:  wmem_din = msg_chunk[352+:32];
            4'd5:  wmem_din = msg_chunk[320+:32];
            4'd6:  wmem_din = msg_chunk[288+:32];
            4'd7:  wmem_din = msg_chunk[256+:32];
            4'd8:  wmem_din = msg_chunk[224+:32];
            4'd9:  wmem_din = msg_chunk[192+:32];
            4'd10: wmem_din = msg_chunk[160+:32];
            4'd11: wmem_din = msg_chunk[128+:32];
            4'd12: wmem_din = msg_chunk[96+:32];
            4'd13: wmem_din = msg_chunk[64+:32];
            4'd14: wmem_din = msg_chunk[32+:32];
            4'd15: wmem_din = msg_chunk[0+:32];
        endcase
    end

    // Values 16-63 are computed using previous values
    else begin
        wmem_din = w16 + s0l + w7 + s1l;
    end
end

// Working variables
logic [31:0] a, b, c, d, e, f, g, h;
logic [31:0] s0u, s1u, t1, t2, ch, maj;

upper_sigma upper_sigma (
    .x0(a),
    .x1(e),
    .s0(s0u),
    .s1(s1u)
);

choice choice (
    .x(e),
    .y(f),
    .z(g),
    .ch(ch)
);

majority majority (
    .x(a),
    .y(b),
    .z(c),
    .maj(maj)
);

assign t1 = h + s1u + ch + kmem_data + wmem_dout;
assign t2 = s0u + maj;

// Variable initialization and compression loop
always_ff @(posedge clk) begin
    if (state_q2 == StInit) begin
        unique case (count_q2[2:0])
            3'd0: a <= hmem_data;
            3'd1: b <= hmem_data;
            3'd2: c <= hmem_data;
            3'd3: d <= hmem_data;
            3'd4: e <= hmem_data;
            3'd5: f <= hmem_data;
            3'd6: g <= hmem_data;
            3'd7: h <= hmem_data; 
        endcase
    end else if (state_q2 == StLoop) begin
        h <= g;
        g <= f;
        f <= e;
        e <= d + t1;
        d <= c;
        c <= b;
        b <= a;
        a <= t1 + t2;
    end
end

// W memory
assign wmem_addr = count_q;
assign wmem_en = (state_q == StWord) || (state_q == StLoop);
assign wmem_we = (state_q == StWord);

// H memory
assign hmem_addr = count_q[2:0];
assign hmem_en = (state_q == StInit) || (state_q == StHash);
assign hmem_we = 1'b0;

// K memory
assign kmem_addr = count_q;
assign kmem_en = (state_q == StLoop);
assign kmem_we = 1'b0;

// Final hash computation
always_ff @(posedge clk) begin
    if (state_q2 == StHash) begin
        unique case (count_q2[2:0])
            3'd0: hash <= {hash[223:0], hmem_data + a};
            3'd1: hash <= {hash[223:0], hmem_data + b};
            3'd2: hash <= {hash[223:0], hmem_data + c};
            3'd3: hash <= {hash[223:0], hmem_data + d};
            3'd4: hash <= {hash[223:0], hmem_data + e};
            3'd5: hash <= {hash[223:0], hmem_data + f};
            3'd6: hash <= {hash[223:0], hmem_data + g};
            3'd7: hash <= {hash[223:0], hmem_data + h}; 
        endcase
    end
end

// Flags
assign done = (state_q2 == StDone);

endmodule
