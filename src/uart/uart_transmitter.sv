module uart_transmitter (
    // Clock / Reset
    input  logic clk,
    input  logic rst,

    // Transmitter
    output logic tx,

    // Data bus
    input  logic [7:0] data,
    input  logic       load
);

// State encodings
typedef enum logic [2:0] { 
    StIdle,
    StStart,
    StData,
    StStop
} state_t;

// State registers
state_t state_d, state_q;
logic [6:0] count_d, count_q;

// State transition logic
always_ff @(posedge clk) begin
    if (rst) begin
        state_q <= StIdle;
        count_q <= '0;
    end else begin
        state_q <= state_d;
        count_q <= count_d;
    end
end

// Next state logic
always_comb begin
    case (state_q)
        StIdle:  state_d = load ? StStart : StIdle;
        StStart: state_d = (count_q == {3'd0, 4'd15}) ? StData : StStart;
        StData:  state_d = (count_q == {3'd7, 4'd15}) ? StStop : StData;
        StStop:  state_d = (count_q == {3'd0, 4'd15}) ? StIdle : StStop;
        default: state_d = StIdle;
    endcase

    case (state_q)
        StIdle:  count_d = '0;
        StStart: count_d = (count_q + 1'b1) % 16;
        StData:  count_d = (count_q + 1'b1);
        StStop:  count_d = (count_q + 1'b1) % 16;
        default: count_d = '0;
    endcase
end

// Packet shift register
logic [9:0] packet;
always_ff @(posedge clk) begin
    if (load)
        packet <= {1'b1, data, 1'b0};
    else if (state_q != StIdle && count_q[3:0] == 4'd15)
        packet <= {1'b1, packet[9:1]};
end

// Transmit packet out LSB first
assign tx = packet[0];

endmodule
