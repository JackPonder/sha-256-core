module padding (
    // Clock / Reset
    input  logic clk,
    input  logic rst,

    // Input bus
    input  logic [7:0] text_data,
    input  logic       text_last,
    input  logic       text_valid,
    output logic       text_ready,

    // Output bus
    output logic [511:0] chunk_data,
    output logic         chunk_valid,
    input  logic         chunk_ready
);

//------------------------------------------------------------------------------
// Control
//------------------------------------------------------------------------------

// State encodings
typedef enum logic [2:0] {
    StInit,
    StText,
    StOne,
    StZero,
    StLength,
    StDone
} state_t;

// State registers
state_t state_d, state_q;
logic [5:0] count_d, count_q;

// State transition logic
always_ff @(posedge clk) begin
    if (rst) begin
        state_q  <= StInit;
        count_q  <= '0;
    end else begin
        state_q  <= state_d;
        count_q  <= count_d;
    end
end

// Next state logic
always_comb begin
    // State transitions
    case (state_q)
        StInit:   state_d = StText;
        StText:   state_d = (text_valid && text_last) ? StOne : StText;
        StOne:    state_d = StZero;
        StZero:   state_d = (count_q == 55) ? StLength : StZero;
        StLength: state_d = (count_q == 63) ? StDone : StLength;
        StDone:   state_d = (chunk_ready) ? StInit : StDone;
        default:  state_d = StInit;
    endcase

    // Counter
    case (state_q)
        StInit:   count_d = '0;
        StText:   count_d = text_valid ? (count_q + 1'b1) : count_q;
        StOne:    count_d = count_q + 1'b1;
        StZero:   count_d = count_q + 1'b1;
        StLength: count_d = count_q + 1'b1;
        StDone:   count_d = '0;
        default:  count_d = '0;
    endcase
end

// Handshake signals
assign text_ready = (state_q == StText);
assign chunk_valid = (state_q == StDone);

// Output logic
wire init = (state_q == StInit);
wire shift_text = (state_q == StText) && text_valid;
wire shift_one = (state_q == StOne);
wire shift_zero = (state_q == StZero);
wire shift_length = (state_q == StLength);

//------------------------------------------------------------------------------
// Datapath
//------------------------------------------------------------------------------

// Message bit length
logic [63:0] msg_bit_length;

always_ff @(posedge clk) begin
    if (init)
        msg_bit_length <= '0;
    if (shift_text)
        msg_bit_length <= msg_bit_length + 64'd8;
end

// Message chunk shift register
always_ff @(posedge clk) begin
    if (shift_text) begin
        chunk_data <= {chunk_data[503:0], text_data};
    end else if (shift_one) begin
        chunk_data <= {chunk_data[503:0], 8'h80};
    end else if (shift_zero) begin
        chunk_data <= {chunk_data[503:0], 8'h00};
    end else if (shift_length) begin
        unique case (count_q[2:0])
            3'd0: chunk_data <= {chunk_data[503:0], msg_bit_length[56+:8]}; 
            3'd1: chunk_data <= {chunk_data[503:0], msg_bit_length[48+:8]}; 
            3'd2: chunk_data <= {chunk_data[503:0], msg_bit_length[40+:8]}; 
            3'd3: chunk_data <= {chunk_data[503:0], msg_bit_length[32+:8]}; 
            3'd4: chunk_data <= {chunk_data[503:0], msg_bit_length[24+:8]}; 
            3'd5: chunk_data <= {chunk_data[503:0], msg_bit_length[16+:8]}; 
            3'd6: chunk_data <= {chunk_data[503:0], msg_bit_length[8+:8]}; 
            3'd7: chunk_data <= {chunk_data[503:0], msg_bit_length[0+:8]}; 
        endcase
    end 
end
    
endmodule
