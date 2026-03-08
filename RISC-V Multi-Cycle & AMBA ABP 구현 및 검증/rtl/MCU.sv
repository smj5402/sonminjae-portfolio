`timescale 1ns / 1ps

module MCU (
    input  logic       clk,
    input  logic       reset,
    output logic [3:0] gpoa,
    output logic [3:0] gpob,
    input  logic [3:0] gpic,
    inout  wire [3:0] gpiod,
    output logic       tx,
    input  logic       rx
);
    // ROM side signals
    logic [31:0] instrCode;
    logic [31:0] instrMemAddr;

    // global signals
    logic        PCLK;
    logic        PRESET;
    // APB Interface Signals
    logic [31:0] PADDR;
    logic        PWRITE;
    logic        PENABLE;
    logic [31:0] PWDATA;

    logic        PSEL_RAM;
    logic        PSEL_GPOA;
    logic        PSEL_GPOB;
    logic        PSEL_GPIC;
    logic        PSEL_GPIOD;
    logic        PSEL_UART;

    logic [31:0] PRDATA_RAM;
    logic [31:0] PRDATA_GPOA;
    logic [31:0] PRDATA_GPOB;
    logic [31:0] PRDATA_GPIC;
    logic [31:0] PRDATA_GPIOD;
    logic [31:0] PRDATA_UART;

    logic        PREADY_RAM;
    logic        PREADY_GPOA;
    logic        PREADY_GPOB;
    logic        PREADY_GPIC;
    logic        PREADY_GPIOD;
    logic        PREADY_UART;

    // Internal Interface Signals
    logic        transfer;
    logic        ready;
    logic        write;
    logic [31:0] addr;
    logic [31:0] wdata;
    logic [31:0] rdata;

    assign PCLK   = clk;
    assign PRESET = reset;

    ROM U_ROM (
        .addr(instrMemAddr),
        .data(instrCode)
    );

    CPU_RV32I U_RV32I_CORE (
        .clk         (clk),
        .reset       (reset),
        .instrCode   (instrCode),
        .instrMemAddr(instrMemAddr),
        .busWe       (write),
        .busAddr     (addr),
        .busWData    (wdata),
        .busRData    (rdata),
        .transfer    (transfer),
        .ready       (ready)
    );

    APB_Master U_APB_Master (
        .*,
        .PSEL0(PSEL_RAM),
        .PSEL1(PSEL_GPOA),
        .PSEL2(PSEL_GPOB),
        .PSEL3(PSEL_GPIC),
        .PSEL4(PSEL_GPIOD),
        .PSEL5(PSEL_UART),

        .PRDATA0(PRDATA_RAM),
        .PRDATA1(PRDATA_GPOA),
        .PRDATA2(PRDATA_GPOB),
        .PRDATA3(PRDATA_GPIC),
        .PRDATA4(PRDATA_GPIOD),
        .PRDATA5(PRDATA_UART),

        .PREADY0(PREADY_RAM),
        .PREADY1(PREADY_GPOA),
        .PREADY2(PREADY_GPOB),
        .PREADY3(PREADY_GPIC),
        .PREADY4(PREADY_GPIOD),
        .PREADY5(PREADY_UART)
    );

    APB_RAM U_APB_RAM (
        .*,
        .PSEL  (PSEL_RAM),
        .PRDATA(PRDATA_RAM),
        .PREADY(PREADY_RAM)
    );

    GPO_Periph U_GPOA (
        .*,
        .PSEL  (PSEL_GPOA),
        .PRDATA(PRDATA_GPOA),
        .PREADY(PREADY_GPOA),
        .gpo   (gpoa)
    );

    GPO_Periph U_GPOB (
        .*,
        .PSEL  (PSEL_GPOB),
        .PRDATA(PRDATA_GPOB),
        .PREADY(PREADY_GPOB),
        .gpo   (gpob)
    );

    GPI_Periph U_GPIC (
        .*,
        .PSEL  (PSEL_GPIC),
        .PRDATA(PRDATA_GPIC),
        .PREADY(PREADY_GPIC),
        .gpi   (gpic)
    );

    GPIO_Periph U_GPIOD (
        .*,
        .PSEL  (PSEL_GPIOD),
        .PRDATA(PRDATA_GPIOD),
        .PREADY(PREADY_GPIOD),
        .gpio  (gpiod)
    );

    UART_Periph U_UART (
        .*,
        .PSEL  (PSEL_UART),
        .PRDATA(PRDATA_UART),
        .PREADY(PREADY_UART),
        .tx    (tx),
        .rx    (rx)
    );

endmodule

