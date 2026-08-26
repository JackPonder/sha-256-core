module sram #(
    parameter ADDR_WIDTH = 8,
    parameter DATA_WIDTH = 32,
    parameter MEM_INIT_FILE = ""
) (
    input  logic                  clk,
    input  logic [ADDR_WIDTH-1:0] addra,
    input  logic                  ena,
    input  logic                  wea,
    input  logic [DATA_WIDTH-1:0] dina,
    output logic [DATA_WIDTH-1:0] douta
);

// Memory array
logic [DATA_WIDTH-1:0] mem [1 << ADDR_WIDTH];
logic [DATA_WIDTH-1:0] drega;

// Synchronous read/write
always_ff @(posedge clk) begin
    if (ena) begin
        if (wea) begin
            mem[addra] <= dina;
        end else begin
            drega <= mem[addra];
        end
    end
end

// Additional output register to improve timing
always_ff @(posedge clk) begin
    douta <= drega;
end

// Memory initialization
initial begin
    if (MEM_INIT_FILE != "")
        $readmemh(MEM_INIT_FILE, mem);
end

endmodule
