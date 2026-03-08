`timescale 1ns / 1ps
module GPIO_Periph (
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
    inout  wire [ 3:0] gpio
);

    logic [3:0] moder;
    logic [3:0] idr;
    logic [3:0] odr;

    APB_SlaveIntf_GPIO U_APB_SlaveIntrf_GPIO (.*);

    GPIO U_GPIO (.*);

endmodule


module GPIO (
    input  logic [3:0] moder,
    output logic [3:0] idr,
    input  logic [3:0] odr,
    inout  wire [3:0] gpio
);
    genvar i;
    generate
        for (i = 0; i < 4; i++) begin
            assign gpio[i] = moder[i] ? odr[i] : 1'bz;  // active high (출력)
            assign idr[i]  = moder[i] ? 1'bz : gpio[i];  // active low  (입력)
            // z 일 때, 전압을 읽을 수 있기 때문에 
        end
    endgenerate
endmodule



module APB_SlaveIntf_GPIO (
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
    input  logic [ 3:0] idr,
    output logic [ 3:0] odr

);
    logic [31:0] slv_reg0, slv_reg1, slv_reg2, slv_reg3;

    assign moder = slv_reg0[3:0];  ///////////////////
    assign odr   = slv_reg2[3:0];
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
                        2'd1: PRDATA <= {28'b0, idr};  ////////////////////
                        2'd2: PRDATA <= slv_reg2;
                        2'd3: PRDATA <= slv_reg3;
                    endcase
                end
            end
        end
    end
endmodule
