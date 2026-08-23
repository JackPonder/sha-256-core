module lower_sigma (
    input  logic [31:0] w0,
    input  logic [31:0] w1,
    output logic [31:0] s0,
    output logic [31:0] s1
);

// Lowercase sigma 0
assign s0 = (
    {w0[6:0],  w0[31:7]}  ^
    {w0[17:0], w0[31:18]} ^
    {3'b0,     w0[31:3]}
);

// Lowercase sigma 1
assign s1 = (
    {w1[16:0], w1[31:17]} ^
    {w1[18:0], w1[31:19]} ^
    {10'b0,    w1[31:10]}
);

endmodule
