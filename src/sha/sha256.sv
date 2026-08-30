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

logic [5:0] wmem_addr;
logic [31:0] wmem_dout;
logic [31:0] wmem_din;
logic wmem_en;
logic wmem_we;

sram #(
    .ADDR_WIDTH(6),
    .DATA_WIDTH(32)
) w_mem (
    .clk(clk),
    .addra(wmem_addr),
    .dina(wmem_din),
    .douta(wmem_dout),
    .ena(wmem_en),
    .wea(wmem_we)
);

logic [2:0] hmem_addr;
logic [31:0] hmem_data;
logic hmem_en;
logic hmem_we;

sram #(
    .ADDR_WIDTH(3),
    .DATA_WIDTH(32),
    .MEM_INIT_FILE("h.mem")
) h_mem (
    .clk(clk),
    .addra(hmem_addr),
    .ena(hmem_en),
    .wea(hmem_we),
    .dina(32'b0),
    .douta(hmem_data)
);

logic [5:0] kmem_addr;
logic [31:0] kmem_data;
logic kmem_en;
logic kmem_we;

sram #(
    .ADDR_WIDTH(6),
    .DATA_WIDTH(32),
    .MEM_INIT_FILE("k.mem")
) k_mem (
    .clk(clk),
    .addra(kmem_addr),
    .ena(kmem_en),
    .wea(kmem_we),
    .dina(32'b0),
    .douta(kmem_data)
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

    .wmem_addr(wmem_addr),
    .wmem_din(wmem_din),
    .wmem_dout(wmem_dout),
    .wmem_en(wmem_en),
    .wmem_we(wmem_we),

    .hmem_addr(hmem_addr),
    .hmem_data(hmem_data),
    .hmem_en(hmem_en),
    .hmem_we(hmem_we),

    .kmem_addr(kmem_addr),
    .kmem_data(kmem_data),
    .kmem_en(kmem_en),
    .kmem_we(kmem_we),
    
    .hash_data(hash_data),
    .hash_valid(hash_valid),
    .hash_ready(hash_ready)
);

endmodule
