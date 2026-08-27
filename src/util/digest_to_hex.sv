module digest_to_hex (
    // Clock / Reset
    input  logic clk,
    input  logic rst,

    // Hash digest
    input  logic [255:0] digest_data,
    input  logic         digest_valid,
    output logic         digest_ready,

    // Ascii hex
    output logic [7:0] hex_data,
    output logic       hex_valid,
    input  logic       hex_ready
);

// State encodings
typedef enum logic { 
    StIdle,
    StShift
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
        StIdle:  state_d = (digest_valid) ? StShift : StIdle;
        StShift: state_d = (hex_ready && count_q == 6'd63) ? StIdle : StShift;
        default: state_d = StIdle;
    endcase

    case (state_q)
        StIdle:  count_d = '0;
        StShift: count_d = hex_ready ? count_q + 1'b1 : count_q;
        default: count_d = '0;
    endcase
end

// Handshake flags
assign digest_ready = (state_q == StIdle);
assign hex_valid = (state_q == StShift);

// Digest register
logic [255:0] digest;
always_ff @(posedge clk) begin
    if (digest_valid && digest_ready)
        digest <= digest_data;
    else if (hex_valid && hex_ready)
        digest <= {digest[251:0], 4'h0};
end

// Output data
assign hex_data = {4'h0, digest[255:252]} + (digest[255:252] < 10 ? 8'h30 : 8'h37);

endmodule
