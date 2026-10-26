 
`timescale 1ns / 1ps

module data_mem #(
    parameter DEPTH = 256
) (
    input  logic        clk,
    input  logic        rst,
    input  logic [31:0] addr,
    input  logic [31:0] write_data,
    input  logic        mem_write,
    input  logic        mem_read,
    input  logic [3:0]  byte_enable,
    output logic [31:0] read_data
);

    logic [31:0] mem [0:DEPTH-1];
    integer i;

    // Synchronous reset and byte-enabled writes
    always_ff @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < DEPTH; i = i + 1)
                mem[i] <= 32'b0;
        end
        else if (mem_write && (addr[31:2] < DEPTH)) begin
            if (byte_enable[0])
                mem[addr[31:2]][7:0] <= write_data[7:0];

            if (byte_enable[1])
                mem[addr[31:2]][15:8] <= write_data[15:8];

            if (byte_enable[2])
                mem[addr[31:2]][23:16] <= write_data[23:16];

            if (byte_enable[3])
                mem[addr[31:2]][31:24] <= write_data[31:24];
        end
    end

    // Asynchronous read of the containing word
    always_comb begin
        read_data = 32'b0;

        if (mem_read && (addr[31:2] < DEPTH))
            read_data = mem[addr[31:2]];
    end

endmodule
