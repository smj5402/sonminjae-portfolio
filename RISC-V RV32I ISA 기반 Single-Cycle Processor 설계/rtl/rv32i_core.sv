`timescale 1ns / 1ps

module rv32i_top (
    input clk,
    input rst,
    output [15:0] led
);

    logic [31:0] instr_raddr, instr_code , dwdata, drdata;
    logic [6:0] daddr;
    logic [1:0] byte_sel;
    logic [3:0] b_we;
    logic [2:0] funct3;
    // logic d_we;

    instruction_memory U_INST_MEM (
        .instr_raddr (instr_raddr),
        .instr_code(led)
    );
    // instruction_memory U_INST_MEM (.*);

    rv32i_core U_RV32I_CORE (.*);

    data_mem U_DATA_MEM (.*);

    assign led = instr_code;


endmodule



module rv32i_core (
    input         clk,
    input         rst,
    input  [31:0] instr_code,
    input  [31:0] drdata,
    output [31:0] instr_raddr,
    output [ 3:0] b_we,
    output [ 6:0] daddr,
    output [31:0] dwdata,
    output [ 2:0] funct3,
    output [ 1:0] byte_sel
);
    logic regfile_we, branch, alu_src_sel;
    logic [2:0] reg_w_src_sel;
    logic [3:0] alu_control;
    logic jal, jalr;

    datapath U_DATA_PATH (.*);

    control_unit U_CONTROL_UNIT (.*);
endmodule

