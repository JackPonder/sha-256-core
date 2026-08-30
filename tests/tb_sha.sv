`timescale 1ns/1ps

module tb_sha();

//------------------------------------------------------------------------------
// Signals
//------------------------------------------------------------------------------

// Settings
localparam int CLK_FREQ = 100e6;
localparam int CLK_PERIOD = 1e9 / CLK_FREQ;

// Test values
string test_inputs[$] = {
    "abc",
    "",
    "abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq",
    "abcdefghbcdefghicdefghijdefghijkefghijklfghijklmghijklmnhijklmnoijklmnopjklmnopqklmnopqrlmnopqrsmnopqrstnopqrstu"
};
logic [255:0] test_outputs[$] = {
    'hba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad,
    'he3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855,
    'h248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1,
    'hcf5b16a778af8380036ce59e7b0492370b249b11e8f07a51afac45037afee9d1
};

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

// Test sequences
initial begin
    while (test_inputs.size() != 0) begin
        test_sequence(test_inputs.pop_front(), test_outputs.pop_front());
    end
end

task automatic test_sequence(input string text, input logic [255:0] digest);
    static int test_id = 1;

    text_valid <= 1'b0;
    hash_ready <= 1'b0;
    repeat(100) @(posedge clk);

    for (int i = 0; i <= text.len();) begin
        text_valid <= 1'b1;
        if (i < text.len()) begin
            text_data <= text[i];
        end else begin
            text_data <= 8'h0d;
        end

        @(posedge clk);
        if (text_valid && text_ready) begin
            i++;
        end
    end

    text_valid <= 1'b0;
    hash_ready <= 1'b1;

    $display("========================================");
    $display("TEST #%0d", test_id++);
    $display("Input: \"%s\"", text);
    $display("Expected Output: %h", digest);
    while (1) begin
        @(posedge clk);
        if (hash_valid && hash_ready) begin
            $display("Actual Output:   %h", hash_data);
            break;
        end
    end
endtask

endmodule
