module datapath (
    // Clock
    input  logic clk,

    // Control
    input  logic [6:0] msg_length,
    input  logic [5:0] read_idx,
    input  logic [5:0] write_idx,
    input  logic       pad,
    input  logic       init,
    input  logic       loop,
    input  logic       comp,

    // Memory data
    input  logic [7:0]  msg_data,
    output logic [31:0] wmem_din,
    input  logic [31:0] wmem_dout,
    input  logic [31:0] hmem_data,
    input  logic [31:0] kmem_data,

    // Computed hash
    output logic [255:0] hash
);

//------------------------------------------------------------------------------
// Padding
//------------------------------------------------------------------------------

logic [511:0] msg_chunk;

// Message bit length
wire [63:0] msg_bit_length = msg_length << 3;

// Message chunk shift register
always_ff @(posedge clk) begin
    if (pad) begin
        if (write_idx < msg_length) begin
            msg_chunk <= {msg_chunk[503:0], msg_data};
        end else if (write_idx == msg_length) begin
            msg_chunk <= {msg_chunk[503:0], 8'h80};
        end else if (write_idx < 56) begin
            msg_chunk <= {msg_chunk[503:0], 8'h00};
        end else begin
            unique case (write_idx[2:0])
                3'd0: msg_chunk <= {msg_chunk[503:0], msg_bit_length[56+:8]}; 
                3'd1: msg_chunk <= {msg_chunk[503:0], msg_bit_length[48+:8]}; 
                3'd2: msg_chunk <= {msg_chunk[503:0], msg_bit_length[40+:8]}; 
                3'd3: msg_chunk <= {msg_chunk[503:0], msg_bit_length[32+:8]}; 
                3'd4: msg_chunk <= {msg_chunk[503:0], msg_bit_length[24+:8]}; 
                3'd5: msg_chunk <= {msg_chunk[503:0], msg_bit_length[16+:8]}; 
                3'd6: msg_chunk <= {msg_chunk[503:0], msg_bit_length[8+:8]}; 
                3'd7: msg_chunk <= {msg_chunk[503:0], msg_bit_length[0+:8]}; 
            endcase
        end 
    end
end

//------------------------------------------------------------------------------
// Message scheduling
//------------------------------------------------------------------------------

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
    if (read_idx  < 16) begin
        unique case (read_idx[3:0])
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

//------------------------------------------------------------------------------
// Compression Loop
//------------------------------------------------------------------------------

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
    if (init) begin
        unique case (write_idx [2:0])
            3'd0: a <= hmem_data;
            3'd1: b <= hmem_data;
            3'd2: c <= hmem_data;
            3'd3: d <= hmem_data;
            3'd4: e <= hmem_data;
            3'd5: f <= hmem_data;
            3'd6: g <= hmem_data;
            3'd7: h <= hmem_data; 
        endcase
    end else if (loop) begin
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

// Final hash computation
always_ff @(posedge clk) begin
    if (comp) begin
        unique case (write_idx [2:0])
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
    
endmodule
