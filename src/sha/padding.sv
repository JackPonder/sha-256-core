module padding (
    // Clock / Reset
    input  logic clk,
    input  logic rst,

    // Input bus
    input  logic [7:0] text_data,
    input  logic       text_valid,
    output logic       text_ready,

    // Output bus
    output logic [511:0] chunk_data,
    output logic         chunk_last,
    output logic         chunk_valid,
    input  logic         chunk_ready
);

//------------------------------------------------------------------------------
// Control
//------------------------------------------------------------------------------

// State encodings
typedef enum logic [1:0] {
    StText,
    StZero,
    StLength
} state_t;

// State registers
state_t state_d, state_q;
logic [6:0] count_d, count_q;

// State transition logic
always_ff @(posedge clk) begin
    if (rst) begin
        state_q <= StText;
        count_q <= '0;
    end else begin
        state_q <= state_d;
        count_q <= count_d;
    end
end

// Next state logic
wire text_last = (text_data == 8'h0d);
always_comb begin
    state_d = state_q;
    count_d = count_q;

    if (chunk_valid) begin
        if (chunk_ready) begin
            if (chunk_last) begin
                state_d = StText;
            end
            count_d = '0;
        end
    end else begin
        case (state_q)
            StText: begin
                if (text_ready && text_valid) begin
                    if (text_last) begin
                        if (count_q == 7'd55) begin
                            state_d = StLength;
                        end else begin
                            state_d = StZero;
                        end
                    end
                    count_d = count_q + 1'b1;
                end
            end

            StZero: begin
                if (count_q == 7'd55) begin
                    state_d = StLength;
                end
                count_d = count_q + 1'b1;
            end

            StLength: begin
                count_d = count_q + 1'b1;
            end

            default: begin
                state_d = state_q;
                count_d = count_q;
            end
        endcase
    end
end

// Handshake signals
assign text_ready = (count_q < 7'd64) && (state_q == StText);
assign chunk_valid = (count_q == 7'd64);
assign chunk_last = (state_q == StLength);

// Shift register signals
wire shift_text = (count_q < 7'd64) && (state_q == StText) && text_valid && !text_last;
wire shift_one = (count_q < 7'd64) && (state_q == StText) && text_valid && text_last;
wire shift_zero = (count_q < 7'd64) && (state_q == StZero);
wire shift_length = (count_q < 7'd64) && (state_q == StLength);

//------------------------------------------------------------------------------
// Datapath
//------------------------------------------------------------------------------

// Message bit length counter
logic [63:0] msg_bit_length;

always_ff @(posedge clk) begin
    if (rst)
        msg_bit_length <= '0;
    else if (shift_text)
        msg_bit_length <= msg_bit_length + 64'd8;
    else if (chunk_ready && chunk_valid && chunk_last)
        msg_bit_length <= '0;
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
