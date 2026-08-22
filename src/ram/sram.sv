module sram #(
    parameter ADDR_WIDTH = 8,
    parameter DATA_WIDTH = 32,
    parameter MEM_INIT_FILE = ""
) (
    input  logic                  clk,
    input  logic [ADDR_WIDTH-1:0] addr,
    input  logic                  en,
    input  logic                  we,
    input  logic [DATA_WIDTH-1:0] write_data,
    output logic [DATA_WIDTH-1:0] read_data
);

// Memory array
logic [DATA_WIDTH-1:0] mem [1 << ADDR_WIDTH];

// Synchronous read/write
always_ff @(posedge clk) begin
    if (en) begin
        if (we) begin
            mem[addr] <= write_data;
        end else begin
            read_data <= mem[addr];
        end
    end
end

// Memory initialization
initial begin
    if (MEM_INIT_FILE != "")
        $readmemh(MEM_INIT_FILE, mem);
end

endmodule
