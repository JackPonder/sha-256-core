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

logic [5:0] wmem_addra, wmem_addrb;
logic [31:0] wmem_douta;
logic [31:0] wmem_dina, wmem_dinb;
logic wmem_ena, wmem_enb;
logic wmem_wea, wmem_web;

sram #(
    .ADDR_WIDTH(6),
    .DATA_WIDTH(32)
) w_mem (
    .clk(clk),

    .addra(wmem_addra),
    .dina(wmem_dina),
    .douta(wmem_douta),
    .ena(wmem_ena),
    .wea(wmem_wea),

    .addrb(wmem_addrb),
    .dinb(32'b0),
    .doutb(wmem_dinb),
    .enb(wmem_enb),
    .web(wmem_web)
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
// Step 1: Padding
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
// Step 2: Message Scheduling
//------------------------------------------------------------------------------

logic decomp_done;

decomp decomp (
    .clk(clk),
    .rst(rst),

    .go(padding_done),
    .done(decomp_done),

    .m_block(m_block),
    .wmem_addr(wmem_addra),
    .wmem_rdata(wmem_douta),
    .wmem_wdata(wmem_dina),
    .wmem_en(wmem_ena),
    .wmem_we(wmem_wea)
);

//------------------------------------------------------------------------------
// Step 3: Compression Loop
//------------------------------------------------------------------------------

compression compression (
    .clk(clk),
    .rst(rst),

    .go(decomp_done),
    .done(done),

    .hmem_addr(hmem_addr),
    .hmem_data(hmem_data),
    .hmem_en(hmem_en),
    .hmem_we(hmem_we),

    .kmem_addr(kmem_addr),
    .kmem_data(kmem_data),
    .kmem_en(kmem_en),
    .kmem_we(kmem_we),

    .wmem_addr(wmem_addrb),
    .wmem_data(wmem_dinb),
    .wmem_en(wmem_enb),
    .wmem_we(wmem_web),

    .hash(hash)
);

endmodule
