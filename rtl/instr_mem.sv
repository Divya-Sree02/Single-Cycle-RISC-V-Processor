 
`timescale 1ns / 1ps

module instr_mem #(
    parameter DEPTH = 256,
    parameter PROGRAM_FILE = "program.hex"
) (
    input  logic [31:0] addr,
    output logic [31:0] instr
);

    logic [31:0] mem [0:DEPTH-1];
    integer i;

    initial begin
        // Default every location to a NOP
        for (i = 0; i < DEPTH; i = i + 1)
            mem[i] = 32'h00000013;

        // Overwrite initialized locations with program instructions
        $readmemh(PROGRAM_FILE, mem);
    end

    always_comb begin
        instr = 32'h00000013;

        if ((addr[1:0] == 2'b00) && ((addr >> 2) < DEPTH))
            instr = mem[addr[31:2]];
    end

endmodule
