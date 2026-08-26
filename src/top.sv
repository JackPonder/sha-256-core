module top (
    // Clock / Reset
    input  logic clk,
    input  logic rst,

    // UART
    input  logic rx,
    output logic tx,

    // LEDs
    output logic [7:0] led
);

//------------------------------------------------------------------------------
// UART Receiver
//------------------------------------------------------------------------------

logic en_rx;

en_gen #(
    .DIVISOR(54)
) en_gen_rx (
    .clk(clk),
    .rst(rst),
    .en(en_rx)
);

logic [7:0] text_data;
logic text_valid;

uart_receiver uart_rx (
    .clk(clk),
    .rst(rst),
    .en(en_rx),
    .rx(rx),
    .data(text_data),
    .valid(text_valid)
);

always_ff @(posedge clk) begin
    if (text_valid)
        led <= text_data;
end

//------------------------------------------------------------------------------
// SHA-256 Core
//------------------------------------------------------------------------------

logic [255:0] hash_data;
logic hash_valid;

sha256 sha256 (
    .clk(clk),
    .rst(rst),

    .text_data(text_data),
    .text_valid(text_valid),
    .text_ready(),

    .hash_data (hash_data),
    .hash_valid(hash_valid),
    .hash_ready(1'b1)
);

//------------------------------------------------------------------------------
// UART Transmitter
//------------------------------------------------------------------------------

logic en_tx;

en_gen #(
    .DIVISOR(868)
) en_gen_tx (
    .clk(clk),
    .rst(rst),
    .en(en_tx)
);

uart_transmitter uart_tx (
    .clk(clk),
    .rst(rst),
    .en(en_tx),
    .tx(tx),
    .data(hash_data[7:0]),
    .load(hash_valid)
);

endmodule
