module control (
    // Clock / Reset
    input  logic clk,
    input  logic rst,

    // Control flags
    input  logic go,
    output logic done,

    // Datapath signals
    output logic [5:0] read_idx,
    output logic [5:0] write_idx,
    output logic       pad,
    output logic       init,
    output logic       loop,
    output logic       comp,

    // Message memory interface
    output logic [5:0] msg_addr,
    output logic       msg_en,
    output logic       msg_we,

    // W memory interface
    output logic [5:0]  wmem_addr,
    output logic        wmem_en,
    output logic        wmem_we,

    // H memory interface
    output logic [2:0]  hmem_addr,
    output logic        hmem_en,
    output logic        hmem_we,

    // K memory interface
    output logic [5:0]  kmem_addr,
    output logic        kmem_en,
    output logic        kmem_we
);

// State encodings
typedef enum logic [2:0] {
    StIdle,
    StPad,
    StStall,
    StWord,
    StInit,
    StLoop,
    StHash,
    StDone
} state_t;

// State registers
state_t state_d, state_q, state_q2;
logic [5:0] count_d, count_q, count_q2;

// State transition logic
always_ff @(posedge clk) begin
    if (rst) begin
        state_q  <= StIdle;
        state_q2 <= StIdle;
        count_q  <= '0;
        count_q2 <= '0;
    end else begin
        state_q  <= state_d;
        state_q2 <= state_q;
        count_q  <= count_d;
        count_q2 <= count_q;
    end
end

// Next state logic
always_comb begin
    // State transitions
    case (state_q)
        StIdle:  state_d = (go) ? StPad : StIdle;
        StPad:   state_d = (count_q == 63) ? StStall : StPad;
        StStall: state_d = StWord;
        StWord:  state_d = (count_q == 63) ? StInit : StWord;
        StInit:  state_d = (count_q == 7) ? StLoop : StInit;
        StLoop:  state_d = (count_q == 63) ? StHash : StLoop;
        StHash:  state_d = (count_q == 7) ? StDone : StHash;
        StDone:  state_d = StIdle;
        default: state_d = StIdle;
    endcase

    // Counter to track loop index
    case (state_q)
        StIdle:  count_d = '0;
        StPad:   count_d = (count_q + 1'b1);
        StStall: count_d = '0;
        StWord:  count_d = (count_q + 1'b1);
        StInit:  count_d = (count_q + 1'b1) % 8;
        StLoop:  count_d = (count_q + 1'b1);
        StHash:  count_d = (count_q + 1'b1) % 8;
        StDone:  count_d = '0;
        default: count_d = '0;
    endcase
end

// Datapath signals
assign pad = (state_q2 == StPad);
assign init = (state_q2 == StInit);
assign loop = (state_q2 == StLoop);
assign comp = (state_q2 == StHash);
assign read_idx = count_q;
assign write_idx = count_q2;

// Message memory control
assign msg_addr = count_q;
assign msg_en = (state_q == StPad);
assign msg_we = 1'b0;

// W memory
assign wmem_addr = count_q;
assign wmem_en = (state_q == StWord) || (state_q == StLoop);
assign wmem_we = (state_q == StWord);

// H memory
assign hmem_addr = count_q[2:0];
assign hmem_en = (state_q == StInit) || (state_q == StHash);
assign hmem_we = 1'b0;

// K memory
assign kmem_addr = count_q;
assign kmem_en = (state_q == StLoop);
assign kmem_we = 1'b0;

// Flags
assign done = (state_q2 == StDone);
    
endmodule
