module uart_transmitter #(
    parameter CLK_FREQ = 100_000_000,
    parameter BAUD_RATE = 115_200
) (
    // Clock / Reset
    input  logic clk,
    input  logic rst,

    // Transmitter
    output logic tx,

    // Data bus
    input  logic [7:0] data,
    input  logic       load,
    output logic       ready
);

// Enable generator to lower clock speed to match baud rate
logic en;

en_gen #(
    .DIVISOR(CLK_FREQ / BAUD_RATE)
) en_gen (
    .clk(clk),
    .rst(rst),
    .en(en)
);

// State encodings
typedef enum logic [1:0] { 
    StIdle,
    StStart,
    StData,
    StStop
} state_t;

// State registers
state_t state_d, state_q;
logic [2:0] count_d, count_q;

// State transition logic
always_ff @(posedge clk) begin
    if (rst) begin
        state_q <= StIdle;
        count_q <= '0;
    end else if (en) begin
        state_q <= state_d;
        count_q <= count_d;
    end
end

// Next state logic
always_comb begin
    case (state_q)
        StIdle:  state_d = load ? StStart : StIdle;
        StStart: state_d = StData;
        StData:  state_d = (count_q == 3'd7) ? StStop : StData;
        StStop:  state_d = StIdle;
        default: state_d = StIdle;
    endcase

    count_d = (state_q == StData) ? (count_q + 1'b1) : '0;
end

// Packet shift register
logic [9:0] packet;
always_ff @(posedge clk) begin
    if (rst)
        packet <= {10{1'b1}};
    else if (en) begin
        if (ready && load)
            packet <= {1'b1, data, 1'b0};
        else if (!ready)
            packet <= {1'b1, packet[9:1]};
    end
end

// Transmit packet out LSB first
assign tx = packet[0];

// Ready flag
assign ready = en && (state_q == StIdle);

endmodule
