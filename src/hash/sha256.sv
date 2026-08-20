module sha256 #(
    parameter OUTPUT_LENGTH = 8,
    parameter MAX_MESSAGE_LENGTH = 55,
    parameter K_NUMBER = 64,
    parameter H_NUMBER = 8
) (
    // Clock / Reset
    input  logic clk,
    input  logic rst,

    // Control
    input  logic [$clog2(MAX_MESSAGE_LENGTH):0] msg_length,
    input  logic                                go,
    output logic                                finish,

    // Message memory interface
    output logic [$clog2(MAX_MESSAGE_LENGTH)-1:0] msg_addr,  // address of letter
    output logic                                  msg_en,
    output logic                                  msg_we,
    input  logic [7:0]                            msg_data,  // read each letter

    // K memory interface
    output logic [$clog2(K_NUMBER)-1:0] kmem_addr,
    output logic                        kmem_en,
    output logic                        kmem_we,
    input  logic [31:0]                 kmem_data,  // read data

    // H memory interface
    output logic [$clog2(H_NUMBER)-1:0] hmem_addr,
    output logic                        hmem_en,
    output logic                        hmem_we,
    input  logic [31:0]                 hmem_data,  // read data

    // Output data memory
    output logic [$clog2(OUTPUT_LENGTH)-1:0] dom_addr,
    output logic [31:0]                      dom_data,  // write data
    output logic                             dom_en,
    output logic                             dom_we
);

logic [511:0] block;

padding #(
    .MAX_MESSAGE_LENGTH(MAX_MESSAGE_LENGTH)
) padding (
    .clk(clk),
    .rst(rst),

    .go(go),
    .done(),

    .msg_length(msg_length),
    .msg_addr(msg_addr),
    .msg_data(msg_data),
    .msg_en(msg_en),
    .msg_we(msg_we),
    .block(block)
);

endmodule
