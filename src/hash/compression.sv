module compression (
    // Clock / Reset
    input  logic clk,
    input  logic rst,

    // Control flags
    input  logic go,
    output logic done,

    // H memory interface
    output logic [2:0]  hmem_addr,
    input  logic [31:0] hmem_data,
    output logic        hmem_en,
    output logic        hmem_we,

    // K memory interface
    output logic [5:0]  kmem_addr,
    input  logic [31:0] kmem_data,
    output logic        kmem_en,
    output logic        kmem_we,

    // W memory interface
    output logic [5:0]  wmem_addr,
    input  logic [31:0] wmem_data,
    output logic        wmem_en,
    output logic        wmem_we
);



endmodule
