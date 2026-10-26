 
`timescale 1ns / 1ps

module imm_generation (
    input  logic [31:0] instr,
    input  logic [2:0]  imm_type,
    output logic [31:0] imm
);

    // Immediate format encodings
    localparam [2:0] IMM_I = 3'b000;
    localparam [2:0] IMM_S = 3'b001;
    localparam [2:0] IMM_B = 3'b010;
    localparam [2:0] IMM_U = 3'b011;
    localparam [2:0] IMM_J = 3'b100;

    always_comb begin
        // Default value
        imm = 32'b0;

        case (imm_type)

            // I-type: ADDI, ANDI, loads, etc.
            IMM_I: begin
                imm = {{20{instr[31]}}, instr[31:20]};
            end

            // S-type: Store instructions
            IMM_S: begin
                imm = {{20{instr[31]}},
                       instr[31:25], instr[11:7]};
            end

            // B-type: Conditional branches
            IMM_B: begin
                imm = {{19{instr[31]}},
                       instr[31], instr[7],
                       instr[30:25], instr[11:8], 1'b0};
            end

            // U-type: LUI and AUIPC
            IMM_U: begin
                imm = {instr[31:12], 12'b0};
            end

            // J-type: JAL
            IMM_J: begin
                imm = {{11{instr[31]}},
                       instr[31], instr[19:12],
                       instr[20], instr[30:21], 1'b0};
            end

            default: imm = 32'b0;

        endcase
    end

endmodule
