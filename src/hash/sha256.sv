module sha256 #(
    parameter MAX_MESSAGE_LENGTH = 55
) (
    // Clock / Reset
    input  logic clk,
    input  logic rst,

    // Control
    input  logic [$clog2(MAX_MESSAGE_LENGTH):0] msg_length,
    input  logic                                go,
    output logic                                done,

    // Message memory interface
    output logic [$clog2(MAX_MESSAGE_LENGTH)-1:0] msg_addr,
    input  logic [7:0]                            msg_data,
    output logic                                  msg_en,
    output logic                                  msg_we,

    // Computed hash
    output logic [255:0] hash
);

//------------------------------------------------------------------------------
// RAMs
//------------------------------------------------------------------------------

logic [5:0] wmem_addr;
logic [31:0] wmem_dout;
logic [31:0] wmem_din;
logic wmem_en;
logic wmem_we;

sram #(
    .ADDR_WIDTH(6),
    .DATA_WIDTH(32)
) w_mem (
    .clk(clk),
    .addra(wmem_addr),
    .dina(wmem_din),
    .douta(wmem_dout),
    .ena(wmem_en),
    .wea(wmem_we)
);

logic [2:0] hmem_addr;
logic [31:0] hmem_data;
logic hmem_en;
logic hmem_we;

sram #(
    .ADDR_WIDTH(3),
    .DATA_WIDTH(32),
    .MEM_INIT_FILE("h.mem")
) h_mem (
    .clk(clk),
    .addra(hmem_addr),
    .ena(hmem_en),
    .wea(hmem_we),
    .dina(32'b0),
    .douta(hmem_data)
);

logic [5:0] kmem_addr;
logic [31:0] kmem_data;
logic kmem_en;
logic kmem_we;

sram #(
    .ADDR_WIDTH(6),
    .DATA_WIDTH(32),
    .MEM_INIT_FILE("k.mem")
) k_mem (
    .clk(clk),
    .addra(kmem_addr),
    .ena(kmem_en),
    .wea(kmem_we),
    .dina(32'b0),
    .douta(kmem_data)
);

//------------------------------------------------------------------------------
// Padding
//------------------------------------------------------------------------------

logic padding_done;
logic [511:0] m_block;

padding #(
    .MAX_MESSAGE_LENGTH(MAX_MESSAGE_LENGTH)
) padding (
    .clk(clk),
    .rst(rst),

    .go(go),
    .done(padding_done),

    .msg_length(msg_length),
    .msg_addr(msg_addr),
    .msg_data(msg_data),
    .msg_en(msg_en),
    .msg_we(msg_we),
    .block(m_block)
);

//------------------------------------------------------------------------------
// Message Scheduling & Compression Loop
//------------------------------------------------------------------------------

compression compression (
    .clk(clk),
    .rst(rst),

    .go(padding_done),
    .msg_chunk(m_block),

    .wmem_addr(wmem_addr),
    .wmem_din(wmem_din),
    .wmem_dout(wmem_dout),
    .wmem_en(wmem_en),
    .wmem_we(wmem_we),

    .hmem_addr(hmem_addr),
    .hmem_data(hmem_data),
    .hmem_en(hmem_en),
    .hmem_we(hmem_we),

    .kmem_addr(kmem_addr),
    .kmem_data(kmem_data),
    .kmem_en(kmem_en),
    .kmem_we(kmem_we),

    .hash(hash),
    .done(done)
);

endmodule
