 
`timescale 1ns / 1ps

module reg_file (
    input  logic        clk,
    input  logic        rst,

    input  logic [4:0]  rs1,
    input  logic [4:0]  rs2,
    output logic [31:0] rd1,
    output logic [31:0] rd2,

    input  logic [4:0]  rd,
    input  logic [31:0] wr_data,
    input  logic        wr_en
);

    logic [31:0] registers [0:31];

    integer i;

    // Synchronous reset and register writes
    always_ff @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < 32; i = i + 1)
                registers[i] <= 32'b0;
        end
        else if (wr_en && (rd != 5'd0)) begin
            registers[rd] <= wr_data;
        end
    end

    // Two asynchronous read ports
    always_comb begin
        rd1 = (rs1 == 5'd0) ? 32'b0 : registers[rs1];
        rd2 = (rs2 == 5'd0) ? 32'b0 : registers[rs2];
    end

endmodule
