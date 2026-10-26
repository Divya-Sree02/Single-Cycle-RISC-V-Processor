 
`timescale 1ns / 1ps

module alu_cntrl (
    input  logic [6:0] opcode,
    input  logic [2:0] funct3,
    input  logic [6:0] funct7,
    output logic [3:0] alu_instr
);

    // ALU operation codes: must match alu.sv
    localparam [3:0] ALU_ADD    = 4'b0000;
    localparam [3:0] ALU_SUB    = 4'b0001;
    localparam [3:0] ALU_AND    = 4'b0010;
    localparam [3:0] ALU_OR     = 4'b0011;
    localparam [3:0] ALU_XOR    = 4'b0100;
    localparam [3:0] ALU_SLT    = 4'b0101;
    localparam [3:0] ALU_SLTU   = 4'b0110;
    localparam [3:0] ALU_SLL    = 4'b0111;
    localparam [3:0] ALU_SRL    = 4'b1000;
    localparam [3:0] ALU_SRA    = 4'b1001;

    localparam [6:0] OP_REG = 7'b0110011;
    localparam [6:0] OP_IMM = 7'b0010011;

    always_comb begin
        // Safe default for unsupported instructions
        alu_instr = ALU_ADD;

        case (opcode)

            // R-type instructions
            OP_REG: begin
                case (funct3)
                    3'b000: begin
                        if (funct7 == 7'b0100000)
                            alu_instr = ALU_SUB;
                        else if (funct7 == 7'b0000000)
                            alu_instr = ALU_ADD;
                    end

                    3'b111:
                        if (funct7 == 7'b0000000)
                            alu_instr = ALU_AND;

                    3'b110:
                        if (funct7 == 7'b0000000)
                            alu_instr = ALU_OR;

                    3'b100:
                        if (funct7 == 7'b0000000)
                            alu_instr = ALU_XOR;

                    3'b010:
                        if (funct7 == 7'b0000000)
                            alu_instr = ALU_SLT;

                    3'b011:
                        if (funct7 == 7'b0000000)
                            alu_instr = ALU_SLTU;

                    3'b001:
                        if (funct7 == 7'b0000000)
                            alu_instr = ALU_SLL;

                    3'b101: begin
                        if (funct7 == 7'b0100000)
                            alu_instr = ALU_SRA;
                        else if (funct7 == 7'b0000000)
                            alu_instr = ALU_SRL;
                    end

                    default: alu_instr = ALU_ADD;
                endcase
            end

            // I-type arithmetic instructions
            OP_IMM: begin
                case (funct3)
                    3'b000: alu_instr = ALU_ADD;   // ADDI
                    3'b111: alu_instr = ALU_AND;   // ANDI
                    3'b110: alu_instr = ALU_OR;    // ORI
                    3'b100: alu_instr = ALU_XOR;   // XORI
                    3'b010: alu_instr = ALU_SLT;   // SLTI
                    3'b011: alu_instr = ALU_SLTU;  // SLTIU
                    3'b001: alu_instr = ALU_SLL;   // SLLI

                    3'b101: begin
                        if (funct7 == 7'b0100000)
                            alu_instr = ALU_SRA;   // SRAI
                        else if (funct7 == 7'b0000000)
                            alu_instr = ALU_SRL;   // SRLI
                    end

                    default: alu_instr = ALU_ADD;
                endcase
            end

            default: alu_instr = ALU_ADD;

        endcase
    end

endmodule
