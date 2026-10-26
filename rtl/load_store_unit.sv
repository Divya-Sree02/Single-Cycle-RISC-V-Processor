 
`timescale 1ns / 1ps

module load_store_unit (
    input  logic        is_load,
    input  logic        is_store,
    input  logic [2:0]  funct3,
    input  logic [1:0]  byte_offset,
    input  logic [31:0] store_data,
    input  logic [31:0] raw_read_data,

    output logic [3:0]  byte_enable,
    output logic [31:0] formatted_store_data,
    output logic [31:0] load_data,
    output logic        access_valid
);

    logic [7:0]  selected_byte;
    logic [15:0] selected_half;

    always_comb begin
        byte_enable          = 4'b0000;
        formatted_store_data = 32'b0;
        load_data            = 32'b0;
        selected_byte        = 8'b0;
        selected_half        = 16'b0;
        access_valid         = 1'b1;

        if (is_store) begin
            case (funct3)
                // SB
                3'b000: begin
                    byte_enable = 4'b0001 << byte_offset;
                    formatted_store_data = {4{store_data[7:0]}};
                end

                // SH
                3'b001: begin
                    if (!byte_offset[0]) begin
                        byte_enable = byte_offset[1]
                                    ? 4'b1100 : 4'b0011;
                        formatted_store_data = {2{store_data[15:0]}};
                    end else begin
                        access_valid = 1'b0;
                    end
                end

                // SW
                3'b010: begin
                    if (byte_offset == 2'b00) begin
                        byte_enable = 4'b1111;
                        formatted_store_data = store_data;
                    end else begin
                        access_valid = 1'b0;
                    end
                end

                default: access_valid = 1'b0;
            endcase
        end
        else if (is_load) begin
            case (funct3)
                // LB: signed byte
                3'b000: begin
                    selected_byte = raw_read_data[byte_offset*8 +: 8];
                    load_data = {{24{selected_byte[7]}}, selected_byte};
                end

                // LH: signed halfword
                3'b001: begin
                    if (!byte_offset[0]) begin
                        selected_half = byte_offset[1]
                                      ? raw_read_data[31:16]
                                      : raw_read_data[15:0];
                        load_data = {{16{selected_half[15]}}, selected_half};
                    end else begin
                        access_valid = 1'b0;
                    end
                end

                // LW: word
                3'b010: begin
                    if (byte_offset == 2'b00)
                        load_data = raw_read_data;
                    else
                        access_valid = 1'b0;
                end

                // LBU: unsigned byte
                3'b100: begin
                    selected_byte = raw_read_data[byte_offset*8 +: 8];
                    load_data = {24'b0, selected_byte};
                end

                // LHU: unsigned halfword
                3'b101: begin
                    if (!byte_offset[0]) begin
                        selected_half = byte_offset[1]
                                      ? raw_read_data[31:16]
                                      : raw_read_data[15:0];
                        load_data = {16'b0, selected_half};
                    end else begin
                        access_valid = 1'b0;
                    end
                end

                default: access_valid = 1'b0;
            endcase
        end
        else begin
            access_valid = 1'b0;
        end
    end

endmodule
