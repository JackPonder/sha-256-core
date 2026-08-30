module en_gen #(
    parameter DIVISOR = 8
) (
    // Clock / Reset
    input  logic clk,
    input  logic rst,

    // Generated enable signal
    output logic en
);

logic [$clog2(DIVISOR)-1:0] count;

always_ff @(posedge clk) begin
    if (rst) begin
        count <= '0;
        en <= 1'b0;
    end else if (count == DIVISOR - 1) begin
        count <= '0;
        en <= 1'b1;
    end else begin
        count <= count + 1'b1;
        en <= 1'b0;
    end
end

endmodule
