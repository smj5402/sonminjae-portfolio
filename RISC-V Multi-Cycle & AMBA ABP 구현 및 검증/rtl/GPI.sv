`timescale 1ns / 1ps


module GPI_Periph (
    // global signals
    input  logic        PCLK,
    input  logic        PRESET,
    // APB Interface Signals
    input  logic [31:0] PADDR,
    input  logic        PWRITE,
    input  logic        PENABLE,
    input  logic [31:0] PWDATA,
    input  logic        PSEL,
    output logic [31:0] PRDATA,
    output logic        PREADY,
    // External Signals
    input logic [ 3:0] gpi
);

    logic [3:0] moder;
    logic [3:0] idr;

    APB_SlaveIntf_GPI U_APB_SlaveIntrf_GPI (.*);

    GPI U_GPI (.*);

endmodule 


module GPI (
    input  logic [3:0] moder,  // Mode Register
    output logic [3:0] idr,    // Input Data Register
    input  logic [3:0] gpi
);

    genvar i;
    generate
        for (i = 0; i < 4; i++) begin
            assign idr[i] = moder ? 1'bz : gpi[i];
        end
    endgenerate

endmodule



module APB_SlaveIntf_GPI (
    // global signals
    input  logic        PCLK,
    input  logic        PRESET,
    // APB Interface Signals
    input  logic [31:0] PADDR,
    input  logic        PWRITE,
    input  logic        PENABLE,
    input  logic [31:0] PWDATA,
    input  logic        PSEL,
    output logic [31:0] PRDATA,
    output logic        PREADY,
    // Internal Signals
    output logic [ 3:0] moder,
    input  logic [ 3:0] idr

);
    logic [31:0] slv_reg0, slv_reg1, slv_reg2, slv_reg3;

    assign moder = slv_reg0[3:0];  ///////////////////
    // assign slv_reg1 = {28'b0, idr};

    always_ff @(posedge PCLK, posedge PRESET) begin
        if (PRESET) begin
            slv_reg0 <= 0;
            slv_reg1 <= 0;
            slv_reg2 <= 0;
            slv_reg3 <= 0;
        end else begin
            PREADY <= 1'b0;
            if (PSEL & PENABLE) begin
                PREADY <= 1'b1;
                if (PWRITE) begin
                    case (PADDR[3:2])
                        2'd0: slv_reg0 <= PWDATA;
                        2'd1: slv_reg1 <= PWDATA;  // idr  read only (No write)
                        2'd2: slv_reg2 <= PWDATA;
                        2'd3: slv_reg3 <= PWDATA;
                    endcase
                end else begin
                    case (PADDR[3:2])
                        2'd0: PRDATA <= slv_reg0;
                        2'd1: PRDATA <= {28'b0, idr};
                        2'd2: PRDATA <= slv_reg2;
                        2'd3: PRDATA <= slv_reg3;
                    endcase
                end
            end
        end
    end
endmodule
