 
`timescale 1ns / 1ps

module control_unit (
    input  logic [6:0] opcode,

    output logic       reg_write,
    output logic       alu_src,
    output logic       mem_write,
    output logic       mem_read,
    output logic [1:0] result_src,
    output logic [2:0] imm_type,
    output logic       branch,
    output logic       jump,
    output logic       jalr,
    output logic       lui,
    output logic       auipc
);

    // Instruction opcodes
    localparam [6:0] OP_REG    = 7'b0110011;
    localparam [6:0] OP_IMM    = 7'b0010011;
    localparam [6:0] OP_LOAD   = 7'b0000011;
    localparam [6:0] OP_STORE  = 7'b0100011;
    localparam [6:0] OP_BRANCH = 7'b1100011;
    localparam [6:0] OP_JAL    = 7'b1101111;
    localparam [6:0] OP_JALR   = 7'b1100111;
    localparam [6:0] OP_LUI    = 7'b0110111;
    localparam [6:0] OP_AUIPC  = 7'b0010111;

    // Immediate format encodings
    localparam [2:0] IMM_I = 3'b000;
    localparam [2:0] IMM_S = 3'b001;
    localparam [2:0] IMM_B = 3'b010;
    localparam [2:0] IMM_U = 3'b011;
    localparam [2:0] IMM_J = 3'b100;

    // Write-back source encodings
    localparam [1:0] WB_ALU = 2'b00;
    localparam [1:0] WB_MEM = 2'b01;
    localparam [1:0] WB_PC4 = 2'b10;

    always_comb begin
        // Safe defaults
        reg_write = 1'b0;
        alu_src   = 1'b0;
        mem_write = 1'b0;
        mem_read  = 1'b0;
        result_src = WB_ALU;
        imm_type  = IMM_I;
        branch    = 1'b0;
        jump      = 1'b0;
        jalr      = 1'b0;
        lui       = 1'b0;
        auipc     = 1'b0;

        case (opcode)

            OP_REG: begin
                reg_write = 1'b1;
            end

            OP_IMM: begin
                reg_write = 1'b1;
                alu_src   = 1'b1;
                imm_type  = IMM_I;
            end

            OP_LOAD: begin
                reg_write = 1'b1;
                alu_src   = 1'b1;
                mem_read  = 1'b1;
                result_src = WB_MEM;
                imm_type  = IMM_I;
            end

            OP_STORE: begin
                alu_src   = 1'b1;
                mem_write = 1'b1;
                imm_type  = IMM_S;
            end

            OP_BRANCH: begin
                branch   = 1'b1;
                imm_type = IMM_B;
            end

            OP_JAL: begin
                reg_write = 1'b1;
                jump      = 1'b1;
                result_src = WB_PC4;
                imm_type  = IMM_J;
            end

            OP_JALR: begin
                reg_write = 1'b1;
                jump      = 1'b1;
                jalr      = 1'b1;
                alu_src   = 1'b1;
                result_src = WB_PC4;
                imm_type  = IMM_I;
            end

            OP_LUI: begin
                reg_write = 1'b1;
                lui       = 1'b1;
                alu_src   = 1'b1;
                imm_type  = IMM_U;
            end

            OP_AUIPC: begin
                reg_write = 1'b1;
                auipc     = 1'b1;
                alu_src   = 1'b1;
                imm_type  = IMM_U;
            end

            default: begin
                // Keep safe defaults for unsupported instructions
            end

        endcase
    end

endmodule
