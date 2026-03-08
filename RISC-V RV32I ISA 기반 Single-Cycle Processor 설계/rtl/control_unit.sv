`timescale 1ns / 1ps
`include "define.vh"

module control_unit (
    input        [31:0] instr_code,
    input        [ 1:0] byte_sel,
    output logic        regfile_we,
    output logic        branch,
    output logic        jal,
    output logic        jalr,
    output logic [ 3:0] alu_control,
    output logic        alu_src_sel,
    output logic [ 2:0] reg_w_src_sel,
    output logic [ 3:0] b_we
);

    logic [6:0] funct7;
    logic [2:0] funct3;
    logic [6:0] opcode;

    assign funct7 = instr_code[31:25];
    assign funct3 = instr_code[14:12];
    assign opcode = instr_code[6:0];

    always_comb begin
        regfile_we    = 1'b0;
        branch        = 1'b0;
        jal           = 1'b0;
        jalr          = 1'b0;
        alu_src_sel   = 1'b0;
        alu_control   = 4'h0;
        reg_w_src_sel = 3'b0;
        b_we          = 4'h0;
        case (opcode)
            `OP_R_TYPE: begin
                // r
                regfile_we  = 1'b1;
                alu_control = {funct7[5], funct3};
            end
            `OP_S_TYPE: begin
                // store
                alu_src_sel = 1'b1;  // choose imm
                alu_control = `ADD;

                case (funct3)
                    `SB: begin
                        case (byte_sel)
                            2'b00: b_we = 4'b0001;
                            2'b01: b_we = 4'b0010;
                            2'b10: b_we = 4'b0100;
                            2'b11: b_we = 4'b1000;
                        endcase
                    end
                    `SH: b_we = byte_sel[1] ? 4'b1100 : 4'b0011;
                    `SW: b_we = 4'b1111;
                endcase
            end
            `OP_I_TYPE: begin
                // i
                regfile_we  = 1'b1;
                alu_src_sel = 1'b1;  // choose imm
                case (funct3)
                    `ADDI:        alu_control = `ADD;
                    `SLTI:        alu_control = `SLT;
                    `XORI:        alu_control = `XOR;
                    `ORI:         alu_control = `OR;
                    `ANDI:        alu_control = `AND;
                    `SLLI:        alu_control = `SLL;
                    `SLTIU:       alu_control = `SLTU;
                    `SRLI, `SRAI: alu_control = funct7[5] ? `SRA : `SRL;
                    default:      alu_control = 4'h0;
                endcase
            end
            `OP_IL_TYPE: begin
                // load
                regfile_we    = 1'b1;
                alu_src_sel   = 1'b1;  // choose imm
                alu_control   = `ADD;
                reg_w_src_sel = 3'b1;
            end
            `OP_B_TYPE: begin
                // branch
                branch      = 1'b1;
                alu_control = {1'b0, funct3};
            end
            `OP_UL_TYPE: begin
                // lui
                regfile_we    = 1'b1;
                reg_w_src_sel = 3'b10;
            end
            `OP_UA_TYPE: begin
                // auipc
                regfile_we    = 1'b1;
                reg_w_src_sel = 3'b11;
            end
            `OP_J_TYPE: begin
                // jal
                regfile_we    = 1'b1;
                jal           = 1'b1;
                reg_w_src_sel = 3'b100;
            end
            `OP_JR_TYPE: begin
                // jalr
                regfile_we    = 1'b1;
                jalr          = 1'b1;
                reg_w_src_sel = 3'b100;
            end
            default: ;
        endcase
    end
endmodule
