 
`timescale 1ns / 1ps

module alu (
    input  logic [31:0] op_1,
    input  logic [31:0] op_2,
    input  logic [3:0]  alu_instr,
    output logic [31:0] result,
    output logic        zero
);

    // ALU operation codes
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
    localparam [3:0] ALU_PASS_B = 4'b1010;

    always_comb begin
        result = 32'b0;

        case (alu_instr)
            ALU_ADD:    result = op_1 + op_2;
            ALU_SUB:    result = op_1 - op_2;
            ALU_AND:    result = op_1 & op_2;
            ALU_OR:     result = op_1 | op_2;
            ALU_XOR:    result = op_1 ^ op_2;

            ALU_SLT:
                result = ($signed(op_1) < $signed(op_2))
                         ? 32'd1 : 32'd0;

            ALU_SLTU:
                result = (op_1 < op_2) ? 32'd1 : 32'd0;

            ALU_SLL: result = op_1 << op_2[4:0];
            ALU_SRL: result = op_1 >> op_2[4:0];
            ALU_SRA: result = $signed(op_1) >>> op_2[4:0];

            ALU_PASS_B: result = op_2;

            default: result = 32'b0;
        endcase
    end

    assign zero = (result == 32'b0);

endmodule
