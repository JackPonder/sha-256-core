`timescale 1ns/1ps

module tb_top();

//------------------------------------------------------------------------------
// Signals
//------------------------------------------------------------------------------

// Settings
localparam CLK_PHASE = 5;
localparam TEXT_LENGTH = 5;

// Test vector
logic [7:0] vector [TEXT_LENGTH];
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
logic         hash_ready = 1'b1;

//------------------------------------------------------------------------------
// Testbench
//------------------------------------------------------------------------------

// Clock generation
initial begin
    clk = 1'b1;
    forever #CLK_PHASE clk = ~clk;
end

// Reset sequence
initial begin
    rst = 0;
    text_data = vector[0];
    text_valid = 1'b0;

    repeat(10) @(posedge clk);
    rst <= 1;

    repeat(10) @(posedge clk);
    rst <= 0;

    repeat(10) @(posedge clk);
    text_valid <= 1'b1;

    for (int i = 1; i < TEXT_LENGTH;) begin
        @(posedge clk);
        if (text_valid && text_ready) begin
            text_data <= vector[i++];
        end
    end

    @(posedge clk);
    text_data <= 8'h00;

    @(posedge clk);
    text_valid <= 1'b0;
end

always begin
    @(posedge clk);
    if (hash_valid) begin
        $display("Computed hash:");
        $display("%h", hash_data);
    end
    wait(!hash_valid);
end

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

endmodule
