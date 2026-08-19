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

    // Associative memory
    localparam DATA_DEPTH = 2 ** ADDR_WIDTH;
    reg [DATA_WIDTH-1:0] mem[DATA_DEPTH] = '{default: 'X};

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

    // Need to accomodate loading during simulation
    // e.g. pe_cntl.v creates event
    string memFile;
    string entry;
    int fileDesc;
    bit [ADDR_WIDTH-1:0] memory_address;
    bit [DATA_WIDTH-1:0] memory_data;

    event loadMemory;
    always begin
        @(loadMemory)
            loadInitFile;
    end

    // load at trailing edge of reset
    initial begin
        memFile = MEM_INIT_FILE;
        -> loadMemory;
    end

    task loadInitFile;
        if (memFile != "") begin
            fileDesc = $fopen(memFile, "r");
            if (fileDesc == 0) begin
                $display("ERROR::readmem file error : %s ", memFile);
                $finish;
            end
            $display("INFO::readmem : %s ", memFile);
            while (!$feof(fileDesc)) begin
                void'($fgets(entry, fileDesc));
                void'($sscanf(entry, "@%x %x", memory_address, memory_data));
                $display("INFO::readmem file contents : %s  : Addr:%h, Data:%h", memFile, memory_address, memory_data);
                mem[memory_address] = memory_data;
            end
            $fclose(fileDesc);
        end
    endtask

endmodule
