 
`timescale 1ns / 1ps

module top_single_cycle #(
    parameter IMEM_DEPTH = 256,
    parameter DMEM_DEPTH = 256,
    parameter PROGRAM_FILE = "program.hex"
) (
    input  logic        clk,
    input  logic        rst,
    output logic [31:0] pc_out,
    output logic [31:0] instr_out
);

    // Instruction fields
    logic [6:0] opcode;
    logic [4:0] rd, rs1, rs2;
    logic [2:0] funct3;
    logic [6:0] funct7;

    // Control signals
    logic       reg_write, alu_src;
    logic       mem_write, mem_read;
    logic [1:0] result_src;
    logic [2:0] imm_type;
    logic       branch, jump, jalr, lui, auipc;

    // Datapath signals
    logic [31:0] pc, pc_plus4, next_pc, instr;
    logic [31:0] reg_data1, reg_data2, immediate;
    logic [31:0] alu_operand2, alu_result;
    logic [31:0] mem_read_data, writeback_data;
    logic [3:0]  alu_instr;
    logic        alu_zero, take_branch;

    // Load/store signals
    logic [3:0]  byte_enable;
    logic [31:0] formatted_store_data;
    logic [31:0] load_data;
    logic        access_valid;
    logic [31:0] memory_write_data;

    // PC calculation
    assign pc_plus4 = pc + 32'd4;

    always_comb begin
        if (jalr)
            next_pc = (reg_data1 + immediate) & 32'hFFFFFFFE;
        else if (jump)
            next_pc = pc + immediate;
        else if (branch && take_branch)
            next_pc = pc + immediate;
        else
            next_pc = pc_plus4;
    end

    prog_cntr pc_unit (
        .clk(clk),
        .rst(rst),
        .en(1'b1),
        .next_pc(next_pc),
        .pc(pc)
    );

    assign pc_out = pc;

    // Instruction memory
    instr_mem #(
        .DEPTH(IMEM_DEPTH),
        .PROGRAM_FILE(PROGRAM_FILE)
    ) instruction_memory (
        .addr(pc),
        .instr(instr)
    );

    assign instr_out = instr;

    // Decode instruction fields
    assign opcode = instr[6:0];
    assign rd     = instr[11:7];
    assign funct3 = instr[14:12];
    assign rs1    = instr[19:15];
    assign rs2    = instr[24:20];
    assign funct7 = instr[31:25];

    // Main control unit
    control_unit control (
        .opcode(opcode),
        .reg_write(reg_write),
        .alu_src(alu_src),
        .mem_write(mem_write),
        .mem_read(mem_read),
        .result_src(result_src),
        .imm_type(imm_type),
        .branch(branch),
        .jump(jump),
        .jalr(jalr),
        .lui(lui),
        .auipc(auipc)
    );

    // Register file
    reg_file registers (
        .clk(clk),
        .rst(rst),
        .rs1(rs1),
        .rs2(rs2),
        .rd1(reg_data1),
        .rd2(reg_data2),
        .rd(rd),
        .wr_data(writeback_data),
        .wr_en(reg_write)
    );

    // Immediate generator
    imm_generation immediate_generator (
        .instr(instr),
        .imm_type(imm_type),
        .imm(immediate)
    );

    // ALU controller
    alu_cntrl alu_controller (
        .opcode(opcode),
        .funct3(funct3),
        .funct7(funct7),
        .alu_instr(alu_instr)
    );

    // ALU operand selection
    assign alu_operand2 = alu_src ? immediate : reg_data2;

    // ALU
    alu arithmetic_logic_unit (
        .op_1(reg_data1),
        .op_2(alu_operand2),
        .alu_instr(alu_instr),
        .result(alu_result),
        .zero(alu_zero)
    );

    // Branch unit
    branch_unit branch_checker (
        .rs1_data(reg_data1),
        .rs2_data(reg_data2),
        .funct3(funct3),
        .take_branch(take_branch)
    );

    // Load/store unit
    load_store_unit memory_access_unit (
        .is_load(mem_read),
        .is_store(mem_write),
        .funct3(funct3),
        .byte_offset(alu_result[1:0]),
        .store_data(reg_data2),
        .raw_read_data(mem_read_data),
        .byte_enable(byte_enable),
        .formatted_store_data(formatted_store_data),
        .load_data(load_data),
        .access_valid(access_valid)
    );

    assign memory_write_data = formatted_store_data;

    // Data memory
    data_mem #(
        .DEPTH(DMEM_DEPTH)
    ) data_memory (
        .clk(clk),
        .rst(rst),
        .addr(alu_result),
        .write_data(memory_write_data),
        .mem_write(mem_write && access_valid),
        .mem_read(mem_read && access_valid),
        .byte_enable(byte_enable),
        .read_data(mem_read_data)
    );

    // Write-back selection
    always_comb begin
        case (result_src)
            2'b00: writeback_data = alu_result;
            2'b01: writeback_data = load_data;
            2'b10: writeback_data = pc_plus4;
            default: writeback_data = 32'b0;
        endcase

        if (lui)
            writeback_data = immediate;

        if (auipc)
            writeback_data = pc + immediate;
    end

endmodule
