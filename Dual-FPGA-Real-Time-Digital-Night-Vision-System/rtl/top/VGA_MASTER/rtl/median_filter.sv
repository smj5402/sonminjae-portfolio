`timescale 1ns / 1ps

module median_filter (
    input  logic       pclk,
    input  logic       reset,
    input  logic       vsync_edge,
    input  logic       valid_in,
    input  logic [7:0] i_grey,
    output logic       valid_out,
    output logic       vsync_out,
    output logic [7:0] o_grey
);

    logic [9:0] column;
    logic [9:0] row;


    always_ff @(posedge pclk) begin
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
    end


    logic [7:0] line0_mem[0:319];  // 3층 대기실
    logic [7:0] line1_mem[0:319];  // 2층 대기실

    wire [7:0] lb0_temp = line0_mem[column];  // 3층 갈 데이터
    wire [7:0] lb1_temp = line1_mem[column];  // 2층 갈 데이터

    always_ff @(posedge pclk) begin
        if (valid_in) begin
            line1_mem[column] <= i_grey; // 방금 사용한 데이터 2층으로기모시기
            line0_mem[column] <= lb1_temp; // 2층 데이터님 3층으님 모시기
        end
    end

    logic [7:0] p00, p01, p02;
    logic [7:0] p10, p11, p12;
    logic [7:0] p20, p21, p22;

    always_ff @(posedge pclk) begin
        if (valid_in) begin
            p22 <= i_grey;  // 1층
            p21 <= p22;
            p20 <= p21;
            p12 <= lb1_temp;  // 2층
            p11 <= p12;
            p10 <= p11;
            p02 <= lb0_temp;  // 3층
            p01 <= p02;
            p00 <= p01;
        end
    end

    logic [7:0] max_R1, med_R1, min_R1;
    logic [7:0] max_R2, med_R2, min_R2;
    logic [7:0] max_R3, med_R3, min_R3;

    logic [7:0] min_of_maxes, med_of_meds, max_of_mins;
    logic [7:0] final_median;

    always_comb begin
        if (p00 >= p01 && p00 >= p02) begin
            max_R1 = p00;
            if (p01 >= p02) begin
                med_R1 = p01;
                min_R1 = p02;
            end else begin
                med_R1 = p02;
                min_R1 = p01;
            end
        end else if (p01 >= p00 && p01 >= p02) begin
            max_R1 = p01;
            if (p00 >= p02) begin
                med_R1 = p00;
                min_R1 = p02;
            end else begin
                med_R1 = p02;
                min_R1 = p00;
            end
        end else begin
            max_R1 = p02;
            if (p00 >= p01) begin
                med_R1 = p00;
                min_R1 = p01;
            end else begin
                med_R1 = p01;
                min_R1 = p00;
            end
        end

        if (p10 >= p11 && p10 >= p12) begin
            max_R2 = p10;
            if (p11 >= p12) begin
                med_R2 = p11;
                min_R2 = p12;
            end else begin
                med_R2 = p12;
                min_R2 = p11;
            end
        end else if (p11 >= p10 && p11 >= p12) begin
            max_R2 = p11;
            if (p10 >= p12) begin
                med_R2 = p10;
                min_R2 = p12;
            end else begin
                med_R2 = p12;
                min_R2 = p10;
            end
        end else begin
            max_R2 = p12;
            if (p10 >= p11) begin
                med_R2 = p10;
                min_R2 = p11;
            end else begin
                med_R2 = p11;
                min_R2 = p10;
            end
        end

        if (p20 >= p21 && p20 >= p22) begin
            max_R3 = p20;
            if (p21 >= p22) begin
                med_R3 = p21;
                min_R3 = p22;
            end else begin
                med_R3 = p22;
                min_R3 = p21;
            end
        end else if (p21 >= p20 && p21 >= p22) begin
            max_R3 = p21;
            if (p20 >= p22) begin
                med_R3 = p20;
                min_R3 = p22;
            end else begin
                med_R3 = p22;
                min_R3 = p20;
            end
        end else begin
            max_R3 = p22;
            if (p20 >= p21) begin
                med_R3 = p20;
                min_R3 = p21;
            end else begin
                med_R3 = p21;
                min_R3 = p20;
            end
        end

        if (max_R1 <= max_R2 && max_R1 <= max_R3) min_of_maxes = max_R1;
        else if (max_R2 <= max_R3) min_of_maxes = max_R2;
        else min_of_maxes = max_R3;

        if (med_R1 >= med_R2 && med_R1 >= med_R3) begin
            if (med_R2 >= med_R3) med_of_meds = med_R2;
            else med_of_meds = med_R3;
        end else if (med_R2 >= med_R1 && med_R2 >= med_R3) begin
            if (med_R1 >= med_R3) med_of_meds = med_R1;
            else med_of_meds = med_R3;
        end else begin
            if (med_R1 >= med_R2) med_of_meds = med_R1;
            else med_of_meds = med_R2;
        end

        if (min_R1 >= min_R2 && min_R1 >= min_R3) max_of_mins = min_R1;
        else if (min_R2 >= min_R3) max_of_mins = min_R2;
        else max_of_mins = min_R3;

        if (min_of_maxes >= med_of_meds && min_of_maxes >= max_of_mins) begin
            if (med_of_meds >= max_of_mins) final_median = med_of_meds;
            else final_median = max_of_mins;
        end else if (med_of_meds >= min_of_maxes && med_of_meds >= max_of_mins) begin
            if (min_of_maxes >= max_of_mins) final_median = min_of_maxes;
            else final_median = max_of_mins;
        end else begin
            if (min_of_maxes >= med_of_meds) final_median = min_of_maxes;
            else final_median = med_of_meds;
        end
    end

    logic valid_q;
    logic vsync_q;

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

    logic [7:0] center_pixel;
    logic [7:0] diff_val;
    logic [7:0] threshold;

    assign center_pixel = p11; // 3x3 배열의 정중앙 데이터
    assign threshold    = 8'd20;  // 임계값 (튜닝 필요: 30~50 추천)

    // 두 값의 절댓값 차이 계산
    always_comb begin
        if (center_pixel > final_median) diff_val = center_pixel - final_median;
        else diff_val = final_median - center_pixel;
    end

    always_ff @(posedge pclk) begin
        if (reset) begin
            o_grey <= 8'd0;
        end else begin
            if (valid_q) begin
                if (row < 2 || column < 2) begin
                    o_grey <= 8'h00;
                end
                if (diff_val > threshold) o_grey <= final_median;
                else o_grey <= center_pixel;
            end
        end
    end
endmodule
