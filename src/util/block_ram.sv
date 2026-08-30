module block_ram #(
    parameter ADDR_WIDTH = 8,
    parameter DATA_WIDTH = 32,
    parameter MEM_INIT_FILE = ""
) (
    input  logic                  clk,
    input  logic [ADDR_WIDTH-1:0] addr,
    input  logic                  en,
    input  logic                  we,
    input  logic [DATA_WIDTH-1:0] din,
    output logic [DATA_WIDTH-1:0] dout
);

// Memory array
logic [DATA_WIDTH-1:0] mem [1 << ADDR_WIDTH];
logic [DATA_WIDTH-1:0] drega;

// Synchronous read/write
always_ff @(posedge clk) begin
    if (en) begin
        if (we) begin
            mem[addr] <= din;
        end else begin
            drega <= mem[addr];
        end
    end
end

// Additional output register to improve timing
always_ff @(posedge clk) begin
    dout <= drega;
end

// Memory initialization
initial begin
    if (MEM_INIT_FILE != "")
        $readmemh(MEM_INIT_FILE, mem);
end

endmodule
