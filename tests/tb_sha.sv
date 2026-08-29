`timescale 1ns/1ps

module tb_sha();

//------------------------------------------------------------------------------
// Signals
//------------------------------------------------------------------------------

// Settings
localparam int CLK_FREQ = 100e6;
localparam int CLK_PERIOD = 1e9 / CLK_FREQ;
localparam int TEST_LENGTH = 6;

// Test vector
logic [7:0] vector [TEST_LENGTH];
initial $readmemh("message.mem", vector);

// Clock / Reset
logic clk;
logic rst;

// Input bus
logic [7:0] text_data;
logic       text_valid;
logic       text_ready;

// Output bus
logic [255:0] hash_data;
logic         hash_valid;
logic         hash_ready;

//------------------------------------------------------------------------------
// DUT
//------------------------------------------------------------------------------

sha256 sha256 (
    .clk(clk),
    .rst(rst),

    .text_data(text_data),
    .text_valid(text_valid),
    .text_ready(text_ready),

    .hash_data(hash_data),
    .hash_valid(hash_valid),
    .hash_ready(hash_ready)
);

//------------------------------------------------------------------------------
// Testbench
//------------------------------------------------------------------------------

// Clock generation
initial begin
    clk = 1'b1;
    forever #(CLK_PERIOD / 2) clk = ~clk;
end

// Reset sequence
initial begin
    rst <= 1;
    repeat(10) @(posedge clk);
    rst <= 0;
    repeat(10) @(posedge clk);
end

// Test sequence
initial begin
    text_data <= vector[0];
    text_valid <= 1'b0;
    hash_ready <= 1'b0;
    repeat(100) @(posedge clk);

    for (int i = 1; i < TEST_LENGTH;) begin
        text_valid <= 1'b1;
        @(posedge clk);
        if (text_valid && text_ready) begin
            text_data <= vector[i++];
        end
    end

    @(posedge clk);
    text_valid <= 1'b0;
    hash_ready <= 1'b1;
end

// Log results
initial begin
    $display("========================================");
    $display("TEST #1");
    $display("Input Text: %s", string'(vector[0:TEST_LENGTH-2]));
    while (1) begin
        @(posedge clk);
        if (hash_valid && hash_ready) begin
            $display("Output Digest: %h", hash_data);
            break;
        end
    end
end

endmodule
