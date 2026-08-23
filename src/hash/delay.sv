module delay #(
    parameter WIDTH = 32,
    parameter DEPTH = 4
) (
    // Clock
    input  logic clk,

    // Input/output data
    input  logic [WIDTH-1:0] din,
    output logic [WIDTH-1:0] dout
);

// Register pipeline
logic [WIDTH-1:0] pipeline [DEPTH];

// Shift pipeline registers each cycle
always_ff @(posedge clk) begin
    pipeline[0] <= din;
    for (int i = 1; i < DEPTH; i++) begin
        pipeline[i] <= pipeline[i-1];
    end
end

// Output last value of the pipeline
assign dout = pipeline[DEPTH-1];

endmodule
