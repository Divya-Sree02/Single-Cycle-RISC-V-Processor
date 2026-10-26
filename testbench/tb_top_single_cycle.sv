 
`timescale 1ns/1ps

module tb_top_single_cycle;

    reg clk = 1'b0;
    reg rst;

    wire [31:0] pc_out;
    wire [31:0] instr_out;

    integer i;
    integer total_checks = 0;

    top_single_cycle #(
        .IMEM_DEPTH(256),
        .DMEM_DEPTH(256),
        .PROGRAM_FILE("program.hex")
    ) dut (
        .clk       (clk),
        .rst       (rst),
        .pc_out    (pc_out),
        .instr_out (instr_out)
    );

    always #5 clk = ~clk;

    // --------------------------------------------------
    // Wait for a specific PC
    // --------------------------------------------------
    task automatic wait_for_pc(input [31:0] target_pc);
        integer cycles;
        begin
            cycles = 0;

            while ((pc_out !== target_pc) && (cycles < 300)) begin
                @(negedge clk);
                cycles = cycles + 1;
            end

            if (pc_out !== target_pc) begin
                $display("FAIL: PC expected=%08h actual=%08h",
                         target_pc, pc_out);
                $fatal(1, "PC timeout");
            end
        end
    endtask

    // --------------------------------------------------
    // Register check
    // --------------------------------------------------
    task automatic check_reg(
        input integer index,
        input [31:0] expected,
        input [255:0] name
    );
        reg [31:0] actual;
        begin
            actual = dut.registers.registers[index];
            total_checks = total_checks + 1;

            if (actual !== expected) begin
                $display(
                    "FAIL: %0s x%0d expected=%08h actual=%08h",
                    name, index, expected, actual
                );
                $fatal(1, "Register check failed");
            end
            else begin
                $display("PASS: %0s = %08h", name, actual);
            end
        end
    endtask

    // --------------------------------------------------
    // Memory check
    // --------------------------------------------------
    task automatic check_mem(
        input integer index,
        input [31:0] expected,
        input [255:0] name
    );
        reg [31:0] actual;
        begin
            actual = dut.data_memory.mem[index];
            total_checks = total_checks + 1;

            if (actual !== expected) begin
                $display(
                    "FAIL: %0s mem[%0d] expected=%08h actual=%08h",
                    name, index, expected, actual
                );
                $fatal(1, "Memory check failed");
            end
            else begin
                $display("PASS: %0s = %08h", name, actual);
            end
        end
    endtask

    // --------------------------------------------------
    // Regression
    // --------------------------------------------------
    initial begin
        rst = 1'b1;

        repeat (3) @(negedge clk);
        rst = 1'b0;

        // ==================================================
        // TEST 1: All six branch types, taken/not taken
        // Branch program is the known sequence supplied.
        // Check before later instructions overwrite registers.
        // ==================================================
        wait_for_pc(32'h00000074);

        $display("\n========== TEST 1: BRANCHES ==========");

        check_reg(1,  32'd5,         "Branch setup x1");
        check_reg(2,  32'd5,         "Branch setup x2");
        check_reg(15, 32'd6,         "Branch setup x15");
        check_reg(16, 32'hFFFFFFFF,  "Branch setup x16");

        check_reg(3,  32'd0,  "BEQ taken");
        check_reg(4,  32'd99, "BEQ not taken");
        check_reg(5,  32'd0,  "BNE taken");
        check_reg(6,  32'd99, "BNE not taken");
        check_reg(7,  32'd0,  "BLT signed taken");
        check_reg(8,  32'd99, "BLT signed not taken");
        check_reg(9,  32'd0,  "BGE signed taken");
        check_reg(10, 32'd99, "BGE signed not taken");
        check_reg(11, 32'd0,  "BLTU taken");
        check_reg(12, 32'd99, "BLTU not taken");
        check_reg(13, 32'd0,  "BGEU taken");
        check_reg(14, 32'd99, "BGEU not taken");

        $display("PASS: All 12 branch outcomes.");

        // ==================================================
        // TEST 2: ALU and immediate operations
        // Checkpoint PC 0xC4.
        // ==================================================
        wait_for_pc(32'h000000C4);

        $display("\n========== TEST 2: ALU ==========");

        check_reg(1,  32'd10, "ADDI x1");
        check_reg(2,  32'd3,  "ADDI x2");

        check_reg(3,  32'd13, "ADD");
        check_reg(4,  32'd7,  "SUB");
        check_reg(5,  32'd2,  "AND");
        check_reg(6,  32'd11, "OR");
        check_reg(7,  32'd9,  "XOR");
        check_reg(8,  32'd0,  "SLT");
        check_reg(9,  32'd0,  "SLTU");
        check_reg(10, 32'd80, "SLL");
        check_reg(11, 32'd1,  "SRL");
        check_reg(12, 32'd1,  "SRA");

        check_reg(13, 32'd10, "ANDI");
        check_reg(14, 32'd11, "ORI");
        check_reg(15, 32'd9,  "XORI");
        check_reg(16, 32'd1,  "SLTI");
        check_reg(17, 32'd1,  "SLTIU");
        check_reg(18, 32'd80, "SLLI");
        check_reg(19, 32'd5,  "SRLI");
        check_reg(20, 32'd5,  "SRAI");

        $display("PASS: All ALU operations.");

        // ==================================================
        // TEST 3: JAL
        // JAL at 0xC4 -> target 0xCC.
        // Link = 0xC8; target writes 42 to x29.
        // ==================================================
        wait_for_pc(32'h000000D0);

        $display("\n========== TEST 3: JAL ==========");

        check_reg(30, 32'h000000C8, "JAL link address");
        check_reg(29, 32'd42,       "JAL target marker");

        // ==================================================
        // TEST 4: JALR
        // JALR at 0xD4 -> target 0xDC.
        // Link = 0xD8; target writes 77 to x29.
        // ==================================================
        wait_for_pc(32'h000000E0);

        $display("\n========== TEST 4: JALR ==========");

        check_reg(5,  32'h000000DC, "JALR target address");
        check_reg(31, 32'h000000D8, "JALR link address");
        check_reg(29, 32'd77,       "JALR target marker");

        // ==================================================
        // TEST 5: Loads and stores
        // Loop instruction is at PC 0x124.
        // ==================================================
        wait_for_pc(32'h00000124);

        $display("\n========== TEST 5: LOAD/STORE ==========");

        check_reg(1,  32'd128,      "Memory base address");
        check_reg(2,  32'h80FF1234, "SW source");

        check_reg(3,  32'hFFFFFF80, "LB sign extension");
        check_reg(4,  32'h00000080, "LBU zero extension");
        check_reg(5,  32'hFFFF80FF, "LH sign extension");
        check_reg(6,  32'h000080FF, "LHU zero extension");
        check_reg(7,  32'h80FF1234, "LW original word");

        check_reg(8,  32'h000000AA, "SB source");
        check_reg(9,  32'h00000678, "SH source");
        check_reg(10, 32'h067812AA, "LW after SB and SH");

        check_reg(11, 32'h00000055, "Second SW source");
        check_reg(12, 32'h00000055, "LW second word");

        check_mem(32, 32'h067812AA, "Memory word at address 128");
        check_mem(33, 32'h00000055, "Memory word at address 132");

        // ==================================================
        // TEST 6: x0 invariant
        // ==================================================
        $display("\n========== TEST 6: x0 ==========");

        check_reg(0, 32'h00000000, "x0 invariant");

        // Only reached if every assertion passes.
        $display("\n========================================");
        $display("ALL SINGLE-CYCLE CPU REGRESSION TESTS PASSED");
        $display("Successful assertions: %0d", total_checks);
        $display("========================================");

        $finish;
    end

endmodule
