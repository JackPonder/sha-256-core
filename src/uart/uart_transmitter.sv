module uart_transmitter (
    // Clock / Reset
    input  logic clk,
    input  logic rst,
    input  logic en,

    // Transmitter
    output logic tx,

    // Data bus
    input  logic [7:0] data,
    input  logic       load
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
    if (load)
        packet <= {1'b1, data, 1'b0};
    else if (state_q != StIdle)
        packet <= {1'b1, packet[9:1]};
end

// Transmit packet out LSB first
assign tx = packet[0];

endmodule
