 
`timescale 1ns / 1ps

module branch_unit (
    input  logic [31:0] rs1_data,
    input  logic [31:0] rs2_data,
    input  logic [2:0]  funct3,
    output logic        take_branch
);

    always_comb begin
        take_branch = 1'b0;

        case (funct3)
            3'b000: take_branch = (rs1_data == rs2_data);                    // BEQ
            3'b001: take_branch = (rs1_data != rs2_data);                    // BNE
            3'b100: take_branch = ($signed(rs1_data) < $signed(rs2_data));   // BLT
            3'b101: take_branch = ($signed(rs1_data) >= $signed(rs2_data));  // BGE
            3'b110: take_branch = (rs1_data < rs2_data);                     // BLTU
            3'b111: take_branch = (rs1_data >= rs2_data);                    // BGEU
            default: take_branch = 1'b0;
        endcase
    end

endmodule
