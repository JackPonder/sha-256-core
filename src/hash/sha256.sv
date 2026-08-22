module sha256 #(
    parameter MAX_MESSAGE_LENGTH = 55,
    parameter K_NUMBER = 64,
    parameter H_NUMBER = 8,
    parameter OUTPUT_LENGTH = 8
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

    // K memory interface
    output logic [$clog2(K_NUMBER)-1:0] kmem_addr,
    input  logic [31:0]                 kmem_data,
    output logic                        kmem_en,
    output logic                        kmem_we,

    // H memory interface
    output logic [$clog2(H_NUMBER)-1:0] hmem_addr,
    input  logic [31:0]                 hmem_data,
    output logic                        hmem_en,
    output logic                        hmem_we,

    // Output data memory
    output logic [$clog2(OUTPUT_LENGTH)-1:0] dom_addr,
    output logic [31:0]                      dom_data,
    output logic                             dom_en,
    output logic                             dom_we
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
// Step 2: Block decomposition
//------------------------------------------------------------------------------

logic decomp_done;
logic [5:0] wmem_addr;
logic [31:0] wmem_rdata;
logic [31:0] wmem_wdata;
logic wmem_en;
logic wmem_we;

decomp decomp (
    .clk(clk),
    .rst(rst),

    .go(padding_done),
    .done(decomp_done),

    .m_block(m_block),
    .wmem_addr(wmem_addr),
    .wmem_rdata(wmem_rdata),
    .wmem_wdata(wmem_wdata),
    .wmem_en(wmem_en),
    .wmem_we(wmem_we)
);

sram #(
    .ADDR_WIDTH(6),
    .DATA_WIDTH(32)
) w_mem (
    .clk(clk),
    .addr(wmem_addr),
    .write_data(wmem_wdata),
    .read_data(wmem_rdata),
    .en(wmem_en),
    .we(wmem_we)
);

assign done = decomp_done;

endmodule
