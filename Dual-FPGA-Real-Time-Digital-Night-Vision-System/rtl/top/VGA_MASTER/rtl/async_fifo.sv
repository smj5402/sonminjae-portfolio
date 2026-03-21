`timescale 1ns / 1ps

// ─────────────────────────────────────────────────────────────
//  async_fifo
//  Dual-clock FIFO with gray-code pointer synchronization
//  Write: wr_clk domain,  Read: rd_clk domain
//  DEPTH must be power of 2
// ─────────────────────────────────────────────────────────────
module async_fifo #(
    parameter DATA_WIDTH = 8,
    parameter DEPTH      = 1024,
    parameter ADDR_WIDTH = $clog2(DEPTH)
) (
    // write side
    input  logic                  wr_clk,
    input  logic                  wr_reset,
    input  logic                  wr_en,
    input  logic [DATA_WIDTH-1:0] wr_data,
    output logic                  full,
    // read side
    input  logic                  rd_clk,
    input  logic                  rd_reset,
    input  logic                  rd_en,
    output logic [DATA_WIDTH-1:0] rd_data,
    output logic                  empty
);

    // ── memory ──────────────────────────────────────────────
    logic [DATA_WIDTH-1:0] mem[0:DEPTH-1];

    // ── write pointer (binary + gray) ───────────────────────
    logic [ADDR_WIDTH:0] wr_bin, wr_bin_next;
    logic [ADDR_WIDTH:0] wr_gray, wr_gray_next;

    // ── read pointer (binary + gray) ────────────────────────
    logic [ADDR_WIDTH:0] rd_bin, rd_bin_next;
    logic [ADDR_WIDTH:0] rd_gray, rd_gray_next;

    // ── synchronized pointers ───────────────────────────────
    // wr_gray → rd_clk domain (for empty check)
    logic [ADDR_WIDTH:0] wr_gray_rd_sync1, wr_gray_rd_sync2;
    // rd_gray → wr_clk domain (for full check)
    logic [ADDR_WIDTH:0] rd_gray_wr_sync1, rd_gray_wr_sync2;

    // ── binary ↔ gray conversion ────────────────────────────
    function automatic [ADDR_WIDTH:0] bin2gray(input [ADDR_WIDTH:0] bin);
        return bin ^ (bin >> 1);
    endfunction

    // ================================================================
    //  Write side (wr_clk domain)
    // ================================================================
    assign wr_bin_next  = wr_bin + (wr_en && !full);
    assign wr_gray_next = bin2gray(wr_bin_next);

    always_ff @(posedge wr_clk or posedge wr_reset) begin
        if (wr_reset) begin
            wr_bin  <= '0;
            wr_gray <= '0;
        end else begin
            wr_bin  <= wr_bin_next;
            wr_gray <= wr_gray_next;
        end
    end

    // write memory
    always_ff @(posedge wr_clk) begin
        if (wr_en && !full) mem[wr_bin[ADDR_WIDTH-1:0]] <= wr_data;
    end

    // sync rd_gray into wr_clk domain
    always_ff @(posedge wr_clk or posedge wr_reset) begin
        if (wr_reset) begin
            rd_gray_wr_sync1 <= '0;
            rd_gray_wr_sync2 <= '0;
        end else begin
            rd_gray_wr_sync1 <= rd_gray;
            rd_gray_wr_sync2 <= rd_gray_wr_sync1;
        end
    end

    // full: MSB 2 bits inverted, rest equal
    assign full = (wr_gray == {~rd_gray_wr_sync2[ADDR_WIDTH:ADDR_WIDTH-1],
                                rd_gray_wr_sync2[ADDR_WIDTH-2:0]});

    // ================================================================
    //  Read side (rd_clk domain)
    // ================================================================
    assign rd_bin_next = rd_bin + (rd_en && !empty);
    assign rd_gray_next = bin2gray(rd_bin_next);

    always_ff @(posedge rd_clk or posedge rd_reset) begin
        if (rd_reset) begin
            rd_bin  <= '0;
            rd_gray <= '0;
        end else begin
            rd_bin  <= rd_bin_next;
            rd_gray <= rd_gray_next;
        end
    end

    // read memory (combinational)
    assign rd_data = mem[rd_bin[ADDR_WIDTH-1:0]];

    // sync wr_gray into rd_clk domain
    always_ff @(posedge rd_clk or posedge rd_reset) begin
        if (rd_reset) begin
            wr_gray_rd_sync1 <= '0;
            wr_gray_rd_sync2 <= '0;
        end else begin
            wr_gray_rd_sync1 <= wr_gray;
            wr_gray_rd_sync2 <= wr_gray_rd_sync1;
        end
    end

    // empty: gray pointers equal
    assign empty = (rd_gray == wr_gray_rd_sync2);

endmodule
