`timescale 1ns/1ps

module tb_uart();

//------------------------------------------------------------------------------
// Signals
//------------------------------------------------------------------------------

// Settings
localparam int CLK_FREQ = 100e6;
localparam int CLK_PERIOD = 1e9 / CLK_FREQ;
localparam int BAUD_RATE = 6.25e6;
localparam int CYCLES_PER_BIT = CLK_FREQ / BAUD_RATE;

// Clock / Reset
logic clk;
logic rst;

// UART
logic rx;

// Data bus
logic [7:0] data;
logic valid;

//------------------------------------------------------------------------------
// DUT
//------------------------------------------------------------------------------

uart_receiver dut (
    .clk(clk),
    .rst(rst),
    .en(1'b1),
    .rx(rx),
    .data(data),
    .valid(valid)
);

//------------------------------------------------------------------------------
// Testbench
//------------------------------------------------------------------------------

// Clock generation
initial begin
    clk = 1'b1;
    forever #(CLK_PERIOD / 2) clk = ~clk;
end

// Test sequence
initial begin
    // Initial values
    rst = 0;
    rx = 1;

    // Reset sequence
    repeat(10) @(posedge clk);
    rst <= 1;
    repeat(10) @(posedge clk);
    rst <= 0;

    // Tests
    for (int i = 1; i <= 4; i++) begin
        repeat($urandom_range(100)) @(posedge clk);
        test_sequence($urandom(), i);
    end
end

task automatic test_sequence(input logic [7:0] vector, input integer test_num);
    // Timeout flag
    bit timeout = 1;

    // Start bit
    repeat(CYCLES_PER_BIT) @(posedge clk);
    rx <= 0;

    // Data bits
    for (int i = 0; i < 8; i++) begin
        repeat(CYCLES_PER_BIT) @(posedge clk);
        rx <= vector[i];
    end

    // Stop bit
    repeat(CYCLES_PER_BIT) @(posedge clk);
    rx <= 1;

    // Wait for and check result
    $display("========================================");
    $display("TEST #%0d", test_num);

    for (int i = 0; i < CYCLES_PER_BIT; i++) begin
        @(posedge clk);
        if (valid) begin
            timeout = 0;
            assert(vector == data) 
                $display("PASSED: Expected %h, Got %h", vector, data); 
            else 
                $display("FAILED: Expected %h, Got %h", vector, data);
            break;
        end
    end

    if (timeout) begin
        $display("FAILED: Valid flag was not asserted in time");
    end
endtask
    
endmodule
