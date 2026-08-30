module sha256 (
    // Clock / Reset
    input  logic clk,
    input  logic rst,

    // Input bus
    input  logic [7:0] text_data,
    input  logic       text_valid,
    output logic       text_ready,

    // Output bus
    output logic [255:0] hash_data,
    output logic         hash_valid,
    input  logic         hash_ready
);

//------------------------------------------------------------------------------
// RAMs
//------------------------------------------------------------------------------

logic [5:0] kmem_addr;
logic [31:0] kmem_data;
logic kmem_en;

block_ram #(
    .ADDR_WIDTH(6),
    .DATA_WIDTH(32),
    .MEM_INIT_FILE("k.mem")
) k_mem (
    .clk(clk),
    .addr(kmem_addr),
    .en(kmem_en),
    .we(1'b0),
    .din(32'b0),
    .dout(kmem_data)
);

//------------------------------------------------------------------------------
// Pre-Processing
//------------------------------------------------------------------------------

logic [511:0] chunk_data;
logic chunk_valid, chunk_ready, chunk_last;

padding padding (
    .clk(clk),
    .rst(rst),

    .text_data(text_data),
    .text_valid(text_valid),
    .text_ready(text_ready),

    .chunk_data(chunk_data),
    .chunk_last(chunk_last),
    .chunk_valid(chunk_valid),
    .chunk_ready(chunk_ready)
);

//------------------------------------------------------------------------------
// Processing
//------------------------------------------------------------------------------

processing processing (
    .clk(clk),
    .rst(rst),

    .chunk_data(chunk_data),
    .chunk_last(chunk_last),
    .chunk_valid(chunk_valid),
    .chunk_ready(chunk_ready),

    .kmem_addr(kmem_addr),
    .kmem_data(kmem_data),
    .kmem_en(kmem_en),
    
    .hash_data(hash_data),
    .hash_valid(hash_valid),
    .hash_ready(hash_ready)
);

endmodule
