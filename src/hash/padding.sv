module padding #(
    parameter MAX_MESSAGE_LENGTH = 55
) (
    // Clock / Reset
    input  logic clk,
    input  logic rst,

    // Control flags
    input  logic go,
    output logic done,

    // Message length
    input  logic [$clog2(MAX_MESSAGE_LENGTH):0] msg_length,

    // Message memory interface
    output logic [$clog2(MAX_MESSAGE_LENGTH)-1:0] msg_addr,
    input  logic [7:0]                            msg_data,
    output logic                                  msg_en,
    output logic                                  msg_we,

    // M block
    output logic [511:0] block
);

//------------------------------------------------------------------------------
// FSM Control logic
//------------------------------------------------------------------------------

// State encodings
typedef enum logic [1:0] {
    StIdle,
    StRead,
    StDone
} state_t;

// State registers
state_t state_d, state_q, state_q2;
logic [5:0] count_d, count_q, count_q2;

// State transition logic
always_ff @(posedge clk) begin
    if (rst) begin
        state_q  <= StIdle;
        state_q2 <= StIdle;
        count_q  <= '0;
        count_q2 <= '0;
    end else begin
        state_q  <= state_d;
        state_q2 <= state_q;
        count_q  <= count_d;
        count_q2 <= count_q;
    end
end

// Next state logic
always_comb begin
    // Default transitions
    state_d = state_q;
    count_d = count_q;

    // State transitions
    unique case (state_q)
        StIdle: if (go) state_d = StRead; 
        StRead: if (count_q == 63) state_d = StDone;
        StDone: state_d = StIdle;
    endcase

    // Increment counter only when in read state
    count_d = (state_q == StRead) ? (count_q + 1'b1) : '0;
end

//------------------------------------------------------------------------------
// Datapath
//------------------------------------------------------------------------------

// Message bit length
wire [63:0] msg_bit_length = msg_length << 3;

// M block shift register
always_ff @(posedge clk) begin
    if (state_q2 == StRead) begin
        if (count_q2 < msg_length) begin
            block <= {block[503:0], msg_data};
        end else if (count_q2 == msg_length) begin
            block <= {block[503:0], 8'h80};
        end else if (count_q2 < 56) begin
            block <= {block[503:0], 8'h00};
        end else begin
            unique case (count_q2[2:0])
                3'd0: block <= {block[503:0], msg_bit_length[56+:8]}; 
                3'd1: block <= {block[503:0], msg_bit_length[48+:8]}; 
                3'd2: block <= {block[503:0], msg_bit_length[40+:8]}; 
                3'd3: block <= {block[503:0], msg_bit_length[32+:8]}; 
                3'd4: block <= {block[503:0], msg_bit_length[24+:8]}; 
                3'd5: block <= {block[503:0], msg_bit_length[16+:8]}; 
                3'd6: block <= {block[503:0], msg_bit_length[8+:8]}; 
                3'd7: block <= {block[503:0], msg_bit_length[0+:8]}; 
            endcase
        end 
    end
end

// Message memory control
assign msg_addr = count_q;
assign msg_en = (state_q == StRead);
assign msg_we = 1'b0;

// Flags
assign done = (state_q2 == StDone);

endmodule
