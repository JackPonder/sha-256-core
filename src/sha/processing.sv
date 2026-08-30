module processing (
    // Clock / Reset
    input  logic clk,
    input  logic rst,

    // Input bus
    input  logic [511:0] chunk_data,
    input  logic         chunk_last,
    input  logic         chunk_valid,
    output logic         chunk_ready,

    // K memory interface
    output logic [5:0]  kmem_addr,
    input  logic [31:0] kmem_data,
    output logic        kmem_en,

    // Output bus
    output logic [255:0] hash_data,
    output logic         hash_valid,
    input  logic         hash_ready
);

//------------------------------------------------------------------------------
// Control
//------------------------------------------------------------------------------

// State encodings
typedef enum logic [2:0] {
    StIdle,
    StInit,
    StChunk,
    StLoop,
    StUpdate,
    StDone
} state_t;

// State registers
state_t state_d, state_q, state_q2, state_q3;
logic [5:0] count_d, count_q;
logic chunk_last_q;

// State transition logic
always_ff @(posedge clk) begin
    if (rst) begin
        state_q  <= StIdle;
        state_q2 <= StIdle;
        state_q3 <= StIdle;
        count_q  <= '0;
    end else begin
        state_q  <= state_d;
        state_q2 <= state_q;
        state_q3 <= state_q2;
        count_q  <= count_d;
    end
end

// Next state logic
always_comb begin
    state_d = state_q;
    count_d = count_q;

    case (state_q)
        StIdle: begin
            state_d = StInit;
        end

        StInit: begin
            state_d = StChunk;
        end

        StChunk: begin
            if (chunk_valid && chunk_ready) begin
                state_d = StLoop;
            end
        end

        StLoop: begin
            if (count_q == 6'd63) begin
                state_d = StUpdate;
            end
            count_d = count_q + 1'b1;
        end

        StUpdate: begin
            if (chunk_last_q) begin
                state_d = StDone;
            end else begin
                state_d = StChunk;
            end
        end

        StDone: begin
            if (hash_valid && hash_ready) begin
                state_d = StInit;
            end
        end

        default: begin
            state_d = StIdle;
            count_d = '0;
        end
    endcase
end

// Handshake signals
assign chunk_ready = (state_q == StChunk);
assign hash_valid = (state_q == StDone) && (state_q3 == StDone);

// K memory
assign kmem_addr = count_q;
assign kmem_en = (state_q == StLoop);

//------------------------------------------------------------------------------
// Datapath
//------------------------------------------------------------------------------

// Message chunk
logic [511:0] chunk;
always_ff @(posedge clk) begin
    if (chunk_ready && chunk_valid) begin
        chunk <= chunk_data;
        chunk_last_q <= chunk_last;
    end
end

// Message scheduling
logic [31:0] wi, w2, w7, w15, w16;
logic [31:0] s0l, s1l;

delay #(
    .WIDTH(32),
    .DEPTH(2)
) delay2 (
    .clk(clk),
    .din(wi),
    .dout(w2)
);

delay #(
    .WIDTH(32),
    .DEPTH(7)
) delay7 (
    .clk(clk),
    .din(wi),
    .dout(w7)
);

delay #(
    .WIDTH(32),
    .DEPTH(15)
) delay15 (
    .clk(clk),
    .din(wi),
    .dout(w15)
);

delay #(
    .WIDTH(32),
    .DEPTH(16)
) delay16 (
    .clk(clk),
    .din(wi),
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
            4'd0:  wi = chunk[480+:32];
            4'd1:  wi = chunk[448+:32];
            4'd2:  wi = chunk[416+:32];
            4'd3:  wi = chunk[384+:32];
            4'd4:  wi = chunk[352+:32];
            4'd5:  wi = chunk[320+:32];
            4'd6:  wi = chunk[288+:32];
            4'd7:  wi = chunk[256+:32];
            4'd8:  wi = chunk[224+:32];
            4'd9:  wi = chunk[192+:32];
            4'd10: wi = chunk[160+:32];
            4'd11: wi = chunk[128+:32];
            4'd12: wi = chunk[96+:32];
            4'd13: wi = chunk[64+:32];
            4'd14: wi = chunk[32+:32];
            4'd15: wi = chunk[0+:32];
        endcase
    end

    // Values 16-63 are computed using previous values
    else begin
        wi = w16 + s0l + w7 + s1l;
    end
end

// Compression loop
logic [31:0] hash[8];
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

assign t1 = h + s1u + ch + kmem_data + w2;
assign t2 = s0u + maj;

// Variable initialization and compression loop
always_ff @(posedge clk) begin
    if (state_q3 == StChunk) begin
        a <= hash[0];
        b <= hash[1];
        c <= hash[2];
        d <= hash[3];
        e <= hash[4];
        f <= hash[5];
        g <= hash[6];
        h <= hash[7];
    end else if (state_q3 == StLoop) begin
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

// Hash values
always_ff @(posedge clk) begin
    if (state_q3 == StInit) begin
        hash[0] <= 32'h6a09e667;
        hash[1] <= 32'hbb67ae85;
        hash[2] <= 32'h3c6ef372;
        hash[3] <= 32'ha54ff53a;
        hash[4] <= 32'h510e527f;
        hash[5] <= 32'h9b05688c;
        hash[6] <= 32'h1f83d9ab;
        hash[7] <= 32'h5be0cd19;
    end else if (state_q3 == StUpdate) begin
        hash[0] <= hash[0] + a;
        hash[1] <= hash[1] + b;
        hash[2] <= hash[2] + c;
        hash[3] <= hash[3] + d;
        hash[4] <= hash[4] + e;
        hash[5] <= hash[5] + f;
        hash[6] <= hash[6] + g;
        hash[7] <= hash[7] + h;
    end
end

// Final hash computation
assign hash_data = {
    hash[0],
    hash[1],
    hash[2],
    hash[3],
    hash[4],
    hash[5],
    hash[6],
    hash[7]
};

endmodule
