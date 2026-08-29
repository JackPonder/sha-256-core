module top (
    // Clock / Reset
    input  logic clk,
    input  logic rst,

    // UART
    input  logic rx,
    output logic tx
);

//------------------------------------------------------------------------------
// UART Receiver
//------------------------------------------------------------------------------

logic [7:0] text_data;
logic text_valid;

uart_receiver uart_rx (
    .clk(clk),
    .rst(rst),
    .rx(rx),
    .data(text_data),
    .valid(text_valid)
);

//------------------------------------------------------------------------------
// SHA-256 Core
//------------------------------------------------------------------------------

logic [255:0] digest_data;
logic digest_valid, digest_ready;

sha256 sha256 (
    .clk(clk),
    .rst(rst),

    .text_data(text_data),
    .text_valid(text_valid),
    .text_ready(),

    .hash_data(digest_data),
    .hash_valid(digest_valid),
    .hash_ready(digest_ready)
);

//------------------------------------------------------------------------------
// Digest to Hex Converter
//------------------------------------------------------------------------------

logic [7:0] hex_data;
logic hex_valid, hex_ready;

digest_to_hex digest_to_hex (
    .clk(clk),
    .rst(rst),

    .digest_data(digest_data),
    .digest_valid(digest_valid),
    .digest_ready(digest_ready),

    .hex_data(hex_data),
    .hex_valid(hex_valid),
    .hex_ready(hex_ready)
);

//------------------------------------------------------------------------------
// UART Transmitter
//------------------------------------------------------------------------------

uart_transmitter uart_tx (
    .clk(clk),
    .rst(rst),
    .tx(tx),
    .data(hex_data),
    .load(hex_valid),
    .ready(hex_ready)
);

endmodule
