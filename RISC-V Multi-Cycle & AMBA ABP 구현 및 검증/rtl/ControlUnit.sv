`timescale 1ns / 1ps
`include "defines.sv"

module ControlUnit (
    // global signals
    input  logic        clk,
    input  logic        reset,
    // ROM side port
    input  logic [31:0] instrCode,
    // DataPath side port
    output logic        PCEn,
    output logic        regFileWe,
    output logic        aluSrcMuxSel,
    output logic [ 3:0] aluControl,
    output logic [ 2:0] RFWDSrcMuxSel,
    output logic        branch,
    output logic        jal,
    output logic        jalr,
    // DataMemory side port
    output logic        busWe,
    output logic        transfer,
    input  logic        ready
);
    wire  [6:0] opcode = instrCode[6:0];
    wire  [3:0] operator = {instrCode[30], instrCode[14:12]};
    logic [10:0] signals;

    assign {PCEn, regFileWe, aluSrcMuxSel, busWe, RFWDSrcMuxSel, branch, jal, jalr, transfer } = signals;

    typedef enum {
        FETCH,
        DECODE,
        R_EXE,
        I_EXE,
        B_EXE,
        LU_EXE,
        AU_EXE,
        J_EXE,
        JL_EXE,
        S_EXE,
        S_MEM,
        L_EXE,
        L_MEM,
        L_WB
    } state_t;

    state_t state, state_next;

    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            state <= FETCH;
        end else begin
            state <= state_next;
        end
    end

    always_comb begin
        state_next = state;
        case (state)
            FETCH:   state_next = DECODE;
            DECODE: begin
                state_next = R_EXE;
                case (opcode)
                    `OP_TYPE_R:  state_next = R_EXE;
                    `OP_TYPE_I:  state_next = I_EXE;
                    `OP_TYPE_B:  state_next = B_EXE;
                    `OP_TYPE_LU: state_next = LU_EXE;
                    `OP_TYPE_AU: state_next = AU_EXE;
                    `OP_TYPE_J:  state_next = J_EXE;
                    `OP_TYPE_JL: state_next = JL_EXE;
                    `OP_TYPE_S:  state_next = S_EXE;
                    `OP_TYPE_L:  state_next = L_EXE;
                    default:     state_next = R_EXE;
                endcase
            end
            R_EXE:   state_next = FETCH;
            I_EXE:   state_next = FETCH;
            B_EXE:   state_next = FETCH;
            LU_EXE:  state_next = FETCH;
            AU_EXE:  state_next = FETCH;
            J_EXE:   state_next = FETCH;
            JL_EXE:  state_next = FETCH;
            S_EXE:   state_next = S_MEM;
            S_MEM:   if(ready)  state_next = FETCH;
            L_EXE:   state_next = L_MEM;
            L_MEM:   if (ready) state_next = L_WB;
            L_WB:    state_next = FETCH;
            default: state_next = FETCH;
        endcase
    end

    always_comb begin
        signals = 0;
        aluControl = `ADD;
        case (state)
            //{PCEn, regFileWe, aluSrcMuxSel, busWe, RFWDSrcMuxSel, branch, jal, jalr, transfer}
            FETCH:  signals = 11'b1_0_0_0_000_0_0_0_0;
            DECODE: signals = 11'b0_0_0_0_000_0_0_0_0;
            R_EXE: begin
                signals = 11'b0_1_0_0_000_0_0_0_0;
                aluControl = operator;
            end
            I_EXE: begin
                signals = 11'b0_1_1_0_000_0_0_0_0;
                if (operator == 4'b1101) aluControl = operator;
                else aluControl = {1'b0, operator[2:0]};
            end
            B_EXE: begin
                signals = 11'b0_0_0_0_000_1_0_0_0;
                aluControl = operator;
            end
            LU_EXE: signals = 11'b0_1_0_0_010_0_0_0_0;
            AU_EXE: signals = 11'b0_1_0_0_011_0_0_0_0;
            J_EXE:  signals = 11'b0_1_0_0_100_0_1_0_0;
            JL_EXE: signals = 11'b0_1_0_0_100_0_1_1_0;
            S_EXE:  signals = 11'b0_0_1_0_000_0_0_0_0;
            S_MEM:  signals = 11'b0_0_1_1_000_0_0_0_1;
            L_EXE:  signals = 11'b0_0_1_0_001_0_0_0_0;
            L_MEM:  signals = 11'b0_0_1_0_001_0_0_0_1;
            L_WB:   signals = 11'b0_1_1_0_001_0_0_0_0;
            default: begin
                signals = 0;
                aluControl = `ADD;
            end
        endcase
    end
endmodule
