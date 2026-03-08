`timescale 1ns / 1ps
`include "defines.sv"

module DataPath (
    input  logic        clk,
    input  logic        reset,
    input  logic [31:0] instrCode,
    input  logic        PCEn,
    input  logic        regFileWe,
    input  logic        aluSrcMuxSel,
    input  logic [ 3:0] aluControl,
    output logic [31:0] instrMemAddr,
    output logic [31:0] busAddr,
    output logic [31:0] busWData,
    input  logic [31:0] busRData,
    input  logic [ 2:0] RFWDSrcMuxSel,
    input  logic        branch,
    input  logic        jal,
    input  logic        jalr
);

    logic [31:0] RFReadData1, RFReadData2, RFWriteData;
    logic [31:0] PC_4_AdderResult;
    logic [31:0] immExt;
    logic [31:0] aluSrcMuxOut, PC_Out;
    logic [31:0] aluResult, RFWDSrcMuxOut;
    logic [31:0] PC_Imm_AdderResult, PCSrcMuxOut;
    logic [31:0] PC_Imm_AdderSrcMuxOut;
    logic PCSrcMuxSel, btaken;
    logic [31:0] ExeReg_aluResult, ExeReg_RFRData2;
    logic [31:0] ExeReg_PCSrcMuxOut;
    logic [31:0] DecReg_immExt;
    logic [31:0] DecReg_RFRData1, DecReg_RFRData2;
    logic [31:0] WBReg_busRData;

    assign RFWriteData  = aluResult;
    assign busAddr      = ExeReg_aluResult;
    assign busWData     = ExeReg_RFRData2;
    assign instrMemAddr = PC_Out;
    assign PCSrcMuxSel  = jal | (btaken & branch);


    register U_ExeReg_ALU (
        .clk  (clk),
        .reset(reset),
        .en   (1'b1),
        .d    (aluResult),
        .q    (ExeReg_aluResult)
    );

    register U_ExeReg_RFRD2 (
        .clk  (clk),
        .reset(reset),
        .en   (1'b1),
        .d    (DecReg_RFRData2),
        .q    (ExeReg_RFRData2)
    );

    RegisterFile U_RegFile (
        .clk(clk),
        .we (regFileWe),
        .RA1(instrCode[19:15]),
        .RA2(instrCode[24:20]),
        .WA (instrCode[11:7]),
        .WD (RFWDSrcMuxOut),
        .RD1(RFReadData1),
        .RD2(RFReadData2)
    );


    register U_DecReg_RFRD1 (
        .clk  (clk),
        .reset(reset),
        .en   (1'b1),
        .d    (RFReadData1),
        .q    (DecReg_RFRData1)
    );

    register U_DecReg_RFRD2 (
        .clk  (clk),
        .reset(reset),
        .en   (1'b1),
        .d    (RFReadData2),
        .q    (DecReg_RFRData2)
    );

    mux_2x1 U_AluSrcMux (
        .sel(aluSrcMuxSel),
        .x0 (DecReg_RFRData2),
        .x1 (DecReg_immExt),
        .y  (aluSrcMuxOut)
    );

    alu U_ALU (
        .aluControl(aluControl),
        .a         (DecReg_RFRData1),
        .b         (aluSrcMuxOut),
        .result    (aluResult),
        .btaken    (btaken)
    );

    register U_WBReg_busRData (
        .clk  (clk),
        .reset(reset),
        .en   (1'b1),
        .d    (busRData),
        .q    (WBReg_busRData)
    );

    mux_5x1 U_RFWDSrcMux (
        .sel(RFWDSrcMuxSel),
        .x0 (aluResult),
        .x1 (WBReg_busRData),
        .x2 (DecReg_immExt),
        .x3 (PC_Imm_AdderResult),
        .x4 (PC_4_AdderResult),
        .y  (RFWDSrcMuxOut)
    );

    immExtend U_ImmExtend (
        .instrCode(instrCode),
        .immExt(immExt)
    );

    register U_DecReg_immExt (
        .clk  (clk),
        .reset(reset),
        .en   (1'b1),
        .d    (immExt),
        .q    (DecReg_immExt)
    );

    adder U_4Adder (
        .a(32'd4),
        .b(PC_Out),
        .y(PC_4_AdderResult)
    );

    mux_2x1 U_PC_Imm_AdderSrcMux (
        .sel(jalr),
        .x0 (PC_Out),
        .x1 (DecReg_RFRData1),
        .y  (PC_Imm_AdderSrcMuxOut)
    );

    adder U_PC_Imm_Adder (
        .a(DecReg_immExt),
        .b(PC_Imm_AdderSrcMuxOut),
        .y(PC_Imm_AdderResult)
    );

    mux_2x1 U_PCSrcMux (
        .sel(PCSrcMuxSel),
        .x0 (PC_4_AdderResult),
        .x1 (PC_Imm_AdderResult),
        .y  (PCSrcMuxOut)
    );

    register U_ExeReg_PCSrcMux (
        .clk  (clk),
        .reset(reset),
        .en   (1'b1),
        .d    (PCSrcMuxOut),
        .q    (ExeReg_PCSrcMuxOut)
    );

    register U_PC (
        .clk  (clk),
        .reset(reset),
        .en   (PCEn),
        .d    (ExeReg_PCSrcMuxOut),
        .q    (PC_Out)
    );

endmodule

module alu (
    input logic [3:0] aluControl,
    input logic [31:0] a,
    input logic [31:0] b,
    output logic [31:0] result,
    output logic btaken
);
    always_comb begin
        result = 0;
        case (aluControl)
            `ADD: result = a + b;
            `SUB: result = a - b;
            `SLL: result = a << b[4:0];
            `SRL: result = a >> b[4:0];
            `SRA: result = $signed(a) >>> b[4:0];
            `SLT: result = ($signed(a) < $signed(b)) ? 1 : 0;
            `SLU: result = a < b ? 1 : 0;
            `XOR: result = a ^ b;
            `OR: result = a | b;
            `AND: result = a & b;
            default: result = 0;
        endcase
    end

    always_comb begin
        btaken = 1'b0;
        case (aluControl[2:0])
            `BEQ: btaken = (a == b);
            `BNE: btaken = (a != b);
            `BLT: btaken = ($signed(a) < $signed(b));
            `BGE: btaken = ($signed(a) >= $signed(b));
            `BLTU: btaken = (a < b);
            `BGEU: btaken = (a >= b);
            default: btaken = 1'b0;
        endcase
    end
endmodule

module RegisterFile (
    input  logic        clk,
    input  logic        we,
    input  logic [ 4:0] RA1,
    input  logic [ 4:0] RA2,
    input  logic [ 4:0] WA,
    input  logic [31:0] WD,
    output logic [31:0] RD1,
    output logic [31:0] RD2
);
    logic [31:0] mem[0:2**5-1];

    always_ff @(posedge clk) begin
        if (we) mem[WA] <= WD;
    end

    assign RD1 = (RA1 != 0) ? mem[RA1] : 32'b0;
    assign RD2 = (RA2 != 0) ? mem[RA2] : 32'b0;
endmodule

module register (
    input  logic        clk,
    input  logic        reset,
    input  logic        en,
    input  logic [31:0] d,
    output logic [31:0] q
);
    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            q <= 0;
        end else begin
            if (en) q <= d;
        end
    end
endmodule

module adder (
    input  logic [31:0] a,
    input  logic [31:0] b,
    output logic [31:0] y
);
    assign y = a + b;
endmodule

module mux_2x1 (
    input  logic        sel,
    input  logic [31:0] x0,
    input  logic [31:0] x1,
    output logic [31:0] y
);
    always_comb begin
        y = 32'b0;
        case (sel)
            1'b0: y = x0;
            1'b1: y = x1;
            default: y = 32'b0;
        endcase
    end
endmodule

module immExtend (
    input  logic [31:0] instrCode,
    output logic [31:0] immExt
);
    wire [6:0] opcode = instrCode[6:0];

    always_comb begin
        immExt = 32'b0;
        case (opcode)
            `OP_TYPE_I: immExt = {{20{instrCode[31]}}, instrCode[31:20]};
            `OP_TYPE_L: immExt = {{20{instrCode[31]}}, instrCode[31:20]};
            `OP_TYPE_S: immExt = {{20{instrCode[31]}}, instrCode[31:25], instrCode[11:7]};
            `OP_TYPE_B:
            immExt = {{20{instrCode[31]}}, instrCode[7], instrCode[30:25], instrCode[11:8], 1'b0};
            `OP_TYPE_LU: immExt = {instrCode[31:12], 12'b0};
            `OP_TYPE_AU: immExt = {instrCode[31:12], 12'b0};
            `OP_TYPE_J:
            immExt = {{12{instrCode[31]}}, instrCode[19:12], instrCode[20], instrCode[30:21], 1'b0};
            `OP_TYPE_JL: immExt = {{20{instrCode[31]}}, instrCode[31:20]};
            default immExt = 32'b0;
        endcase
    end
endmodule

module mux_5x1 (
    input  logic [ 2:0] sel,
    input  logic [31:0] x0,
    input  logic [31:0] x1,
    input  logic [31:0] x2,
    input  logic [31:0] x3,
    input  logic [31:0] x4,
    output logic [31:0] y
);
    always_comb begin
        y = 0;
        case (sel)
            3'd0: y = x0;
            3'd1: y = x1;
            3'd2: y = x2;
            3'd3: y = x3;
            3'd4: y = x4;
            default: y = 0;
        endcase
    end
endmodule
