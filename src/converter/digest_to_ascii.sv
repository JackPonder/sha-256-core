module digest_to_ascii (
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

// State registers
logic shifting_d, shifting_q;
logic [6:0] count_d, count_q;

// State transition logic
always_ff @(posedge clk) begin
    if (rst) begin
        shifting_q <= 1'b0;
        count_q <= '0;
    end else begin
        shifting_q <= shifting_d;
        count_q <= count_d;
    end
end

// Next state logic
always_comb begin
    if (!shifting_q) begin
        shifting_d = digest_valid && digest_ready;
        count_d = '0;
    end else begin
        shifting_d = !(hex_valid && hex_ready && count_q == 7'd65);
        count_d = (hex_valid && hex_ready) ? count_q + 1'b1 : count_q;
    end
end

// Handshake flags
assign digest_ready = !shifting_q;
assign hex_valid = shifting_q;

// Digest register
logic [255:0] digest;
always_ff @(posedge clk) begin
    if (digest_valid && digest_ready)
        digest <= digest_data;
    else if (hex_valid && hex_ready)
        digest <= {digest[251:0], 4'h0};
end

// Output data
wire [3:0] hex_char = digest[255:252];
wire [7:0] ascii_offset = (hex_char < 10) ? 8'h30 : 8'h57;
always_comb begin
    case (count_q)
        7'd64:   hex_data = 8'h0d;
        7'd65:   hex_data = 8'h0a; 
        default: hex_data = 8'(hex_char) + ascii_offset;
    endcase
end

endmodule
