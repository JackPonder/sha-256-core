module sram #(
    parameter ADDR_WIDTH = 8,
    parameter DATA_WIDTH = 32,
    parameter MEM_INIT_FILE = ""
) (
    // Clock
    input  logic                  clk,

    // Port A
    input  logic [ADDR_WIDTH-1:0] addra,
    input  logic                  ena,
    input  logic                  wea,
    input  logic [DATA_WIDTH-1:0] dina,
    output logic [DATA_WIDTH-1:0] douta,

    // Port B
    input  logic [ADDR_WIDTH-1:0] addrb,
    input  logic                  enb,
    input  logic                  web,
    input  logic [DATA_WIDTH-1:0] dinb,
    output logic [DATA_WIDTH-1:0] doutb
);

// Memory array
logic [DATA_WIDTH-1:0] mem [1 << ADDR_WIDTH];

// Port A read/write
always_ff @(posedge clk) begin
    if (ena) begin
        if (wea) begin
            mem[addra] <= dina;
        end else begin
            douta <= mem[addra];
        end
    end
end

// Port B read/write
always_ff @(posedge clk) begin
    if (enb) begin
        if (web) begin
            mem[addrb] <= dinb;
        end else begin
            doutb <= mem[addrb];
        end
    end
end

// Memory initialization
initial begin
    if (MEM_INIT_FILE != "")
        $readmemh(MEM_INIT_FILE, mem);
end

endmodule
