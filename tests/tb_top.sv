`timescale 1ns/1ps
`define MSG_LENGTH 5

module tb_top();

//------------------------------------------------------------------------------
// Signals
//------------------------------------------------------------------------------

// Settings
localparam CLK_PHASE = 5;
localparam MAX_MESSAGE_LENGTH = 55;

// Clock / Reset
logic clk;
logic rst;

// Inputs / Outputs
logic                                xxx__dut__go;
logic [$clog2(MAX_MESSAGE_LENGTH):0] xxx__dut__msg_length;
logic [255:0]                        dut__xxx__hash;
logic                                dut__xxx__done;

// Message memory
logic [$clog2(MAX_MESSAGE_LENGTH)-1:0] dut__msg__address;
logic                                  dut__msg__enable;
logic                                  dut__msg__write;
logic [7:0]                            msg__dut__data;

//------------------------------------------------------------------------------
// Testbench
//------------------------------------------------------------------------------

// Clock generation
initial begin
    clk = 1'b0;
    forever #CLK_PHASE clk = ~clk;
end

integer num_cycles;
bit running;

initial begin
    running = 0;

    repeat(10) @(posedge clk);
    rst = 0;
    xxx__dut__go = 0;
    xxx__dut__msg_length = `MSG_LENGTH;

    repeat(10) @(posedge clk);
    rst = 1;
    repeat(10) @(posedge clk);
    rst = 0;

    repeat(1) @(posedge clk);
    xxx__dut__go = 1;
    repeat(1) @(posedge clk);
    xxx__dut__go = 0;
end

always begin
    @(posedge clk);
    if((xxx__dut__go == 1'b1) && !running) begin
        $display("t=%0t, go asserted", $time);
        num_cycles = 0;
        running = 1;
    end else if((dut__xxx__done == 1'b1) && running) begin
        $display("t=%0t, done asserted after %0d clock cycles", $time, num_cycles);
        running = 0;
    end else begin
        num_cycles++;
    end
end

always begin
    @(posedge clk);
    if(dut__xxx__done == 1'b1) begin
        $display("Computed hash:");
        $display("%h", dut__xxx__hash);
    end
    wait(dut__xxx__done == 1'b0);
end

//------------------------------------------------------------------------------
// RAMs
//------------------------------------------------------------------------------

sram #(
    .ADDR_WIDTH($clog2(MAX_MESSAGE_LENGTH)),
    .DATA_WIDTH(8),
    .MEM_INIT_FILE("message.mem")
) msg_mem (
    .addra(dut__msg__address),
    .dina(8'b0),
    .douta(msg__dut__data),
    .ena(dut__msg__enable),
    .wea(dut__msg__write),
    .clk(clk)
);

//------------------------------------------------------------------------------
// DUT
//------------------------------------------------------------------------------

sha256 #(
    .MAX_MESSAGE_LENGTH(MAX_MESSAGE_LENGTH)
) dut (
    .clk(clk),
    .rst(rst),

    .go(xxx__dut__go),
    .msg_length(xxx__dut__msg_length),

    .msg_addr(dut__msg__address),
    .msg_en(dut__msg__enable),
    .msg_we(dut__msg__write),
    .msg_data(msg__dut__data),

    .hash(dut__xxx__hash),
    .done(dut__xxx__done)
);

endmodule
