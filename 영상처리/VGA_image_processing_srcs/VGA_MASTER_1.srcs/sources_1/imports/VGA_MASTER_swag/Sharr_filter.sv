`timescale 1ns / 1ps

module Sharr_filter (
    input  logic       pclk,
    input  logic       reset,
    input  logic       btnU,
    input  logic       btnD,
    input  logic [7:0] i_gray,
    input  logic       valid_in,
    input  logic       vsync_edge,
    output logic       valid_out,
    output logic       vsync_out,
    output logic [7:0] o_rgb
);
    logic [ 9:0] column;
    logic [ 9:0] row;


    logic [13:0] scharr_threshold;

    logic btnU_edge, btnD_edge;
    logic btnU_prev, btnD_prev;


    always_ff @(posedge pclk or posedge reset) begin
        if (reset) begin
            btnU_prev <= 0;
            btnD_prev <= 0;
        end else begin
            btnU_prev <= btnU;
            btnD_prev <= btnD;
        end
    end

    assign btnU_edge = (!btnU_prev && btnU);
    assign btnD_edge = (!btnD_prev && btnD);

    always_ff @(posedge pclk or posedge reset) begin
        if (reset) begin
            scharr_threshold <= 14'd500;
        end else begin
            if (btnU_edge && scharr_threshold < 14'd1200) begin
                scharr_threshold <= scharr_threshold + 14'd25;
            end else if (btnD_edge && scharr_threshold >= 14'd0) begin
                scharr_threshold <= scharr_threshold - 14'd25;
            end
        end
    end


    always_ff @(posedge pclk)
        if (reset || vsync_edge) begin
            column <= 0;
            row <= 0;
        end else if (valid_in) begin
            if (column == 10'd319) begin
                column <= 0;
                if (row == 10'd239) begin
                    row <= 0;
                end else begin
                    row <= row + 1;
                end
            end else begin
                column <= column + 1;
            end
        end


    logic [7:0] line0_mem[0:319];  // 3층 대기실
    logic [7:0] line1_mem[0:319];  // 2층 대기실

    wire [7:0] lb0_temp = line0_mem[column];  // 3층 갈 데이터
    wire [7:0] lb1_temp = line1_mem[column];  // 2층 갈 데이터

    always_ff @(posedge pclk) begin
        if (valid_in) begin
            line1_mem[column] <= i_gray; // 방금 사용한 데이터 2층으로 모시기
            line0_mem[column] <= lb1_temp; // 2층 데이터님 3층으님 모시기
        end
    end

    logic [7:0] p11, p12, p13;
    logic [7:0] p21, p22, p23;
    logic [7:0] p31, p32, p33;

    always_ff @(posedge pclk) begin
        if (valid_in) begin
            p33 <= i_gray;
            p32 <= p33;
            p31 <= p32;  // 1층 (현재 데이터)
            p23 <= lb1_temp;
            p22 <= p23;
            p21 <= p22;  // 2층 데이터
            p13 <= lb0_temp;
            p12 <= p13;
            p11 <= p12;  // 3층 데이터
        end
    end

    logic signed [14:0] Gx, Gy;  //연산중 1비트 넘치는거 생각
    logic [14:0] abs_G;
    logic [ 7:0] scharr_rgb;
    always_comb begin
        Gx = ($signed({1'b0, p13}) * 3 + $signed({1'b0, p23}) * 10 +
              $signed({1'b0, p33}) * 3) -
            ($signed({1'b0, p11}) * 3 + $signed({1'b0, p21}) * 10 +
             $signed({1'b0, p31}) * 3);

        Gy = ($signed({1'b0, p31}) * 3 + $signed({1'b0, p32}) * 10 +
              $signed({1'b0, p33}) * 3) -
            ($signed({1'b0, p11}) * 3 + $signed({1'b0, p12}) * 10 +
             $signed({1'b0, p13}) * 3);

        abs_G = (Gx < 0 ? -Gx : Gx) + (Gy < 0 ? -Gy : Gy);

        if (abs_G > scharr_threshold)
            scharr_rgb = 8'hFF;  // 가장 강한 에지 (흰색)
        else scharr_rgb = 8'h00;  // 에지 강도에 따른 회색
        // else scharr_rgb = abs_G[12:5];  // 에지 강도에 따른 회색
    end

    logic valid_q;
    logic vsync_q;

    always_ff @(posedge pclk) begin
        if (reset) begin
            o_rgb <= 8'd0;
        end else begin
            if (valid_q) begin
                if (row < 2 || column < 2) begin
                    o_rgb <= 8'h00;
                end else begin
                    o_rgb <= scharr_rgb;
                end
            end
        end
    end

    always_ff @(posedge pclk) begin
        if (reset) begin
            valid_q   <= 1'b0;
            valid_out <= 1'b0;
            vsync_q   <= 1'b0;
            vsync_out <= 1'b0;
        end else begin
            valid_q   <= valid_in;
            vsync_q   <= vsync_edge;

            valid_out <= valid_q;
            vsync_out <= vsync_q;
        end
    end

endmodule
