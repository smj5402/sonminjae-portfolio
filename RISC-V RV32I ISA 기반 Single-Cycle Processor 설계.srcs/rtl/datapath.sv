// `define SIMULATION
`timescale 1ns / 1ps
`include "define.vh"

module datapath (
    input               clk,
    input               rst,
    input               regfile_we,
    input               branch,
    input               jal,
    input               jalr,
    input               alu_src_sel,
    input        [ 3:0] alu_control,
    input        [ 2:0] reg_w_src_sel,
    input        [31:0] instr_code,     // instruction code from rom   
    input        [31:0] drdata,         // from data memory
    output       [31:0] instr_raddr,    // pc to rom
    output       [ 6:0] daddr,          // to data ram address
    output       [ 1:0] byte_sel,       // to data ram 
    output logic [31:0] dwdata,         // to data ram data
    output       [ 2:0] funct3
);

    logic [31:0]
        alu_result,
        rdata1,
        rdata2,
        alu_src_2,
        o_imm,
        reg_w_src,
        o_auipc,
        pc_next;

    logic btaken;

    assign daddr    = alu_result[8:2];
    assign byte_sel = alu_result[1:0];
    assign dwdata = rdata2;
    assign funct3 = instr_code[14:12];

    mux_rf_wd_src U_REG_W_SRC_MUX (
        .in_0   (alu_result),
        .in_1   (drdata),
        .in_2   (o_imm),          // from extends imm
        .in_3   (o_auipc),        // AUIPC from PC
        .in_4   (pc_next),        // pc+4 from pc
        .mux_sel(reg_w_src_sel),
        .mux_out(reg_w_src)       // to register file
    );
    register_file U_REG_FILE (
        .clk   (clk),
        .rst   (rst),
        .raddr1(instr_code[19:15]),  // instruction code rs1
        .raddr2(instr_code[24:20]),  // instruction code rs2
        .waddr (instr_code[11:7]),   // instruction code rd
        .wdata (reg_w_src),          // from reg_w_src_sel
        .we    (regfile_we),         // from control unit
        .rdata1(rdata1),             // to alu a
        .rdata2(rdata2)              // to alu b
    );


    alu U_ALU (
        .alu_control(alu_control),  // from control unit
        .a          (rdata1),       // rs1
        .b          (alu_src_2),    // rs2
        .btaken     (btaken),       // branch op
        .alu_result (alu_result)
    );

    mux_2x1 U_ALU_SRC_MUX (
        .in_0   (rdata2),
        .in_1   (o_imm),
        .mux_sel(alu_src_sel),
        .mux_out(alu_src_2)
    );


    extend_imm U_EXTEND_IMM (
        .instr_code(instr_code),
        .o_imm     (o_imm)
    );


    program_counter U_PC (
        .clk    (clk),
        .rst    (rst),
        .branch (branch),
        .btaken (btaken),
        .imm    (o_imm),
        .rdata1 (rdata1),
        .jal    (jal),
        .jalr   (jalr),
        .o_auipc(o_auipc),      // to U_REG_W_SRC_MUX
        .curr_pc(instr_raddr),
        .pc_next(pc_next)
    );

endmodule


module program_counter (
    input         clk,
    input         rst,
    input         branch,
    input         btaken,
    input  [31:0] imm,
    input  [31:0] rdata1,   // from register_file
    input         jal,
    input         jalr,
    output [31:0] o_auipc,
    output [31:0] curr_pc,
    output [31:0] pc_next
);

    logic [31:0] alu_pc_next, o_mux_jalr, mux_pc_next;  //branch_mux
    // logic [31:0] pc_branch;

    // assign pc_branch = curr_pc + imm;

    assign pc_next = alu_pc_next;



    // for pc, rs1
    mux_2x1 U_JALR_MUX (
        .in_0   (curr_pc),
        .in_1   (rdata1),
        .mux_sel(jalr),
        .mux_out(o_mux_jalr)
    );

    alu_pc U_ALU_AUIPC (
        .a    (imm),
        .b    (o_mux_jalr),
        .o_alu(o_auipc)
    );

    mux_2x1 U_PC_SRC_MUX (
        .in_0(alu_pc_next),
        .in_1(o_auipc),
        .mux_sel(jal | jalr | (branch & btaken)),
        .mux_out(mux_pc_next)
    );

    alu_pc U_ALU_PC (
        .a    (32'd4),
        .b    (curr_pc),
        .o_alu(alu_pc_next)
    );

    register U_REG_PC (
        .clk     (clk),
        .rst     (rst),
        .data_in (mux_pc_next),
        .data_out(curr_pc)
    );

endmodule


module alu_pc (
    input  [31:0] a,
    input  [31:0] b,
    output [31:0] o_alu
);
    assign o_alu = a + b;
endmodule


// for program counter
module register (
    input               clk,
    input               rst,
    input        [31:0] data_in,
    output logic [31:0] data_out
);

    logic [31:0] register;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            register <= 32'd0; // PC count init for 32'h0000 address  : 0번 부터 program을 시작하도록 (program address)
        end else begin
            register <= data_in;
        end
    end

    assign data_out = register;


endmodule

module register_file (
    input         clk,
    input         rst,
    input  [ 4:0] raddr1,  // instruction code rs 1
    input  [ 4:0] raddr2,  // instruction code rs 2
    input  [ 4:0] waddr,   // instruction code rd
    input  [31:0] wdata,   // alu output
    input         we,      // from control unit
    output [31:0] rdata1,  // to alu a
    output [31:0] rdata2   // to alu b
);

    logic [31:0] register_file[0:31];

`ifdef SIMULATION
    initial begin
        for (int i = 0; i < 32; i++) register_file[i] = i;

        // r-type
        register_file[13] = 32'hffff_ffff;  // signed : -1 / unsigned : 2^32-1
        register_file[11] = 32'd1;
        register_file[19] = 32'hffff_fffb;  // signed : -5

        // // i-type
        // register_file[3] = 32'hffff_ffff; // signed : -1 / unsigned : 2^32-1
        // register_file[17] = 32'hffff_fffb; // signed : -5

        // // b-type
        // register_file[1] = 32'd2; // for BEQ x2, x1
        // register_file[7] = 32'hffff_ffff; // signed : -1
        // register_file[8] = 32'd1;

        // // store & load
        // register_file[1] = 32'h0000_00ff; // byte
        // register_file[2] = 32'h0000_ffff; // half
        // register_file[3] = 32'hffff_ffff; // word
    end
`endif



    always_ff @(posedge clk) begin
        if (rst) begin
            for (int i = 0; i < 32; i++) register_file[i] = 32'h0;
            register_file[2] <= 32'd127;
        end else if (we && (waddr != 5'd0)) begin
            register_file[waddr] <= wdata;
        end
    end

    assign rdata1 = (raddr1 == 0) ? 32'b0 : register_file[raddr1];
    assign rdata2 = (raddr2 == 0) ? 32'b0 : register_file[raddr2];

endmodule


module alu (
    input        [ 3:0] alu_control,  // from control unit
    input        [31:0] a,
    input        [31:0] b,
    output logic        btaken,
    output logic [31:0] alu_result
);

    always_comb begin
        alu_result = 0;
        case (alu_control)
            `ADD:    alu_result = a + b;
            `SUB:    alu_result = a - b;
            `SLL:    alu_result = a << b[4:0];
            `SLT:    alu_result = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0;
            `SLTU:   alu_result = a < b ? 32'd1 : 32'd0;
            `XOR:    alu_result = a ^ b;
            `SRL:    alu_result = a >> b[4:0];
            `SRA:    alu_result = $signed(a) >>> b[4:0];
            `OR:     alu_result = a | b;
            `AND:    alu_result = a & b;
            default: alu_result = 32'd0;
        endcase
    end

    always_comb begin
        btaken = 1'b0;
        case (alu_control)
            `BEQ:    btaken = a == b;
            `BNE:    btaken = a != b;
            `BLT:    btaken = ($signed(a) < $signed(b));
            `BGE:    btaken = ($signed(a) >= $signed(b));
            `BLTU:   btaken = a < b;    // unsigned
            `BGEU:   btaken = a >= b;   // unsigned
            default: btaken = 1'b0;
        endcase
    end

endmodule

module extend_imm (
    input        [31:0] instr_code,
    output logic [31:0] o_imm
);

    always_comb begin
        o_imm = 32'b0;
        case (instr_code[6:0])
            `OP_S_TYPE: begin
                o_imm = {
                    {20{instr_code[31]}}, instr_code[31:25], instr_code[11:7]
                };
            end
            `OP_I_TYPE, `OP_IL_TYPE: begin
                o_imm = {{20{instr_code[31]}}, instr_code[31:20]};
            end
            `OP_B_TYPE: begin
                // 19 bit sign extends by instr_code[31] + imm[12] + imm[11] + imm[10:5] + imm[4:1] + 1'b0
                o_imm = {
                    {19{instr_code[31]}},
                    instr_code[31],
                    instr_code[7],
                    instr_code[30:25],
                    instr_code[11:8],
                    1'b0
                };
            end
            `OP_UL_TYPE, `OP_UA_TYPE: begin
                o_imm = {instr_code[31:12], 12'h000};
            end
            `OP_J_TYPE: begin
                o_imm = {
                    {11{instr_code[31]}},
                    instr_code[31],
                    instr_code[19:12],
                    instr_code[20],
                    instr_code[30:21],
                    1'b0
                };
            end
            `OP_JR_TYPE: begin
                o_imm = {{20{instr_code[31]}}, instr_code[31:20]};
            end
            default: ;
        endcase
    end
endmodule

module mux_2x1 (
    input  [31:0] in_0,
    input  [31:0] in_1,
    input         mux_sel,
    output [31:0] mux_out
);

    assign mux_out = mux_sel ? in_1 : in_0;

endmodule

module mux_rf_wd_src (
    input        [31:0] in_0,     // from alu_result
    input        [31:0] in_1,     // from data memory
    input        [31:0] in_2,     // LUI
    input        [31:0] in_3,     // AUIPC
    input        [31:0] in_4,
    input        [ 2:0] mux_sel,
    output logic [31:0] mux_out
);

    always_comb begin
        mux_out = in_0;
        case (mux_sel)
            3'b000:  mux_out = in_0;
            3'b001:  mux_out = in_1;
            3'b010:  mux_out = in_2;
            3'b011:  mux_out = in_3;
            3'b100:  mux_out = in_4;
            default: mux_out = in_0;
        endcase
    end

endmodule
