module uart_receiver (
    // Clock / Reset
    input  logic clk,
    input  logic rst,
    input  logic en,

    // Receiver
    input  logic rx,

    // Data bus
    output logic [7:0] data,
    output logic       valid
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
logic [6:0] count_d, count_q;

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
        StIdle:  state_d = (rx == 1'b0) ? StStart : StIdle;
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

// Data shift register
always_ff @(posedge clk) begin
    if (en && state_q == StData && count_q[3:0] == 4'd7)
        data <= {rx, data[7:1]};
end

// Assert valid for one cycle after last bit is read
always_ff @(posedge clk) begin
    if (en && state_q == StStop && count_q == '0)
        valid <= 1'b1;
    else
        valid <= 1'b0;
end
    
endmodule
