module upper_sigma (
    input  logic [31:0] x0,
    input  logic [31:0] x1,
    output logic [31:0] s0,
    output logic [31:0] s1
);

// Uppercase sigma 0
assign s0 = (
    {x0[1:0],  x0[31:2]} ^
    {x0[12:0], x0[31:13]} ^
    {x0[21:0], x0[31:22]}
);

// Uppercase sigma 1
assign s1 = (
    {x1[5:0],  x1[31:6]} ^
    {x1[10:0], x1[31:11]} ^
    {x1[24:0], x1[31:25]}
);

endmodule
