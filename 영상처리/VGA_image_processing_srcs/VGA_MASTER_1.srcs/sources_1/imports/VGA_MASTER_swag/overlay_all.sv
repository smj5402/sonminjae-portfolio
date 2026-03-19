`timescale 1ns / 1ps

module overlay_all #(
    parameter x_start = 100,
    parameter y_start = 100
) (
    input  logic        clk,
    input  logic        reset,
    input  logic        DE,
    input  logic        sw_scale,
    input  logic [ 7:0] distance,
    input  logic [ 7:0] angle,
    input  logic        dist_valid,
    input  logic [ 7:0] x_number,
    input  logic [ 7:0] y_number,
    input  logic [ 9:0] x_pixel,
    input  logic [ 9:0] y_pixel,
    input  logic [11:0] i_rgb,
    output logic [11:0] o_rgb
    // 만약 Top 모듈에서 5클럭 지연된 DE가 필요하다면 아래 포트를 추가하세요.
    // output logic       o_DE 
);

    // =========================================================
    // 1. 기존 테두리 로직 (현재 0-Clock 지연 상태)
    // =========================================================
    logic frame_on;
    assign frame_on = ((x_pixel >= 0) && (x_pixel < 4) || ((x_pixel >= 635) && (x_pixel < 640))) ||
                      ((y_pixel >= 0) && (y_pixel < 5) || ((y_pixel >= 476) && (y_pixel < 480)));

    // 레이더 플래그 신호 (레이더 내부에서 4-Clock 지연되어 나옴)
    logic dot_on, line_on, circle_on, radar_frame_on;


    // =========================================================
    // 2. ★ 동기화 파이프라인 (0-Clock 신호들을 4-Clock 지연 신호로 변환)
    // =========================================================
    logic [11:0] i_rgb_d1, i_rgb_d2, i_rgb_d3, i_rgb_d4;
    logic frame_on_d1, frame_on_d2, frame_on_d3, frame_on_d4;
    logic DE_d1, DE_d2, DE_d3, DE_d4, DE_d5;

    always_ff @(posedge clk) begin
        // 외부 배경색 지연
        i_rgb_d1 <= i_rgb;
        i_rgb_d2 <= i_rgb_d1;
        i_rgb_d3 <= i_rgb_d2;
        i_rgb_d4 <= i_rgb_d3;

        // 화면 테두리 플래그 지연
        frame_on_d1 <= frame_on;
        frame_on_d2 <= frame_on_d1;
        frame_on_d3 <= frame_on_d2;
        frame_on_d4 <= frame_on_d3;

        // DE 신호 지연
        DE_d1 <= DE;
        DE_d2 <= DE_d1;
        DE_d3 <= DE_d2;
        DE_d4 <= DE_d3;
        DE_d5 <= DE_d4; // (선택) Top 모듈에서 모니터로 보낼 최종 DE 신호
    end

    // 만약 Top에서 지연된 DE를 요구한다면 assign 해줍니다.
    // assign o_DE = DE_d5;


    // =========================================================
    // 3. 레이어 합성 (이제 모든 신호가 정확히 4-Clock 시점이라 픽셀이 일치함!)
    // =========================================================
    logic [11:0] rgb_next;

    always_comb begin
        rgb_next = 12'h0;
        if (frame_on_d4) begin  // ✅ 4클럭 지연된 테두리 사용
            rgb_next = 12'hFFF;
        end else if (dot_on) begin       // ✅ 레이더에서 4클럭 지연되어 나옴
            rgb_next = 12'hF00;
        end else if (line_on) begin
            rgb_next = 12'h0F0;
        end else if (circle_on) begin
            rgb_next = 12'h080;
        end else if (radar_frame_on) begin
            rgb_next = 12'h111;
        end else begin
            rgb_next = i_rgb_d4;  // ✅ 4클럭 지연된 배경색 사용
        end
    end


    // =========================================================
    // 4. 최종 출력 레지스터 (4-Clock 데이터를 담아 5-Clock 시점으로 출력)
    // =========================================================
    always_ff @(posedge clk) begin
        // ✅ 4번째 클럭의 데이터(rgb_next)를 쓸지 말지 결정하므로 DE_d4를 쓰는 것이 맞음!
        if (DE_d4) o_rgb <= rgb_next;
        else o_rgb <= 12'h0;
    end


    // =========================================================
    // 5. 레이더 모듈 연결
    // =========================================================
    radar U_RADER (
        .clk           (clk),
        .reset         (reset),
        .sw_scale      (sw_scale),
        .distance      (distance),
        .angle         (angle),
        .dist_valid    (dist_valid),
        .x_pixel       (x_pixel),
        .y_pixel       (y_pixel),
        .dot_on        (dot_on),
        .line_on       (line_on),
        .circle_on     (circle_on),
        .radar_frame_on(radar_frame_on)
    );

endmodule


`timescale 1ns / 1ps

module radar (
    input logic       clk,
    input logic       reset,
    input logic       sw_scale,
    input logic [7:0] distance,
    input logic [7:0] angle,
    input logic       dist_valid,
    input logic [9:0] x_pixel,
    input logic [9:0] y_pixel,
    // 파이프라인 딜레이로 인해 출력 신호도 레지스터(ff)로 변경됨
    output logic dot_on,
    output logic line_on,
    output logic circle_on,
    output logic radar_frame_on
);

    localparam int X_CENTER = 320;
    localparam int Y_CENTER = 479;
    localparam bit WIDE_MONITOR_FIX = 1'b1;

    assign radar_frame_on = 1'b1;

    logic [19:0] sin_cos_mem[0:90];  // 0 ~90도 
    initial begin
        $readmemh("sin_cos_table.mem", sin_cos_mem);
    end

    logic [ 6:0] rom_addr;
    logic [ 7:0] rom_addr_calc;
    logic [19:0] rom_data;
    logic [9:0] rom_sin_raw, rom_cos_raw;
    logic [9:0] sin_val, cos_val;
    logic cos_sign;

    assign rom_addr_calc = (angle <= 8'd90) ? angle : (8'd180 - angle);
    assign rom_addr = rom_addr_calc[6:0];
    assign rom_data = sin_cos_mem[rom_addr];

    assign sin_val = rom_data[19:10];
    assign cos_val = rom_data[9:0];

    logic [9:0] radar_tar_x[0:180];
    logic [9:0] radar_tar_y[0:180];
    logic [180:0] radar_tar_vld;
    logic [31:0] dist_scale;
    assign dist_scale = sw_scale ? ((distance * 32'd241) >> 8) + 32'd80 : ((distance * 32'd241) >> 6) + 32'd80;

    // 4-Stage 타겟 좌표 계산 파이프라인
    // 파이프라인 레지스터 
    logic dist_valid_p1, dist_valid_p2, dist_valid_p3;
    logic [7:0] angle_p1, angle_p2, angle_p3;
    logic [9:0] cos_val_p1, sin_val_p1;
    logic [31:0] dist_scale_p1;
    logic [31:0] mult_x_p2, mult_y_p2;
    logic [9:0] tar_x_p3, tar_y_p3;

    // Stage 1: 1차 스케일링 (거리 곱셈 + 덧셈) 및 각도/삼각함수 래치
    always_ff @(posedge clk) begin
        if (reset) begin
            dist_valid_p1 <= 1'b0;
            dist_scale_p1 <= 32'd0;
        end else begin
            dist_valid_p1 <= dist_valid;
            angle_p1      <= angle;
            dist_scale_p1 <= dist_scale;
            // 다음 스테이지를 위해 현재 각도의 sin/cos 값 저장
            cos_val_p1    <= cos_val;
            sin_val_p1    <= sin_val;
        end
    end

    // Stage 2: 2차 주 곱셈 
    always_ff @(posedge clk) begin
        if (reset) begin
            dist_valid_p2 <= 1'b0;
        end else begin
            dist_valid_p2 <= dist_valid_p1;
            angle_p2      <= angle_p1;
            // DSP 타이밍 확보
            mult_x_p2     <= dist_scale_p1 * cos_val_p1;
            mult_y_p2     <= dist_scale_p1 * sin_val_p1;
        end
    end

    // Stage 3: 비율 보정(*3), 시프트(>>), 중심점 이동(X/Y_CENTER)
    always_ff @(posedge clk) begin
        if (reset) begin
            dist_valid_p3 <= 1'b0;
        end else begin
            dist_valid_p3 <= dist_valid_p2;
            angle_p3      <= angle_p2;

            if (WIDE_MONITOR_FIX) begin
                tar_x_p3 <= (angle_p2 < 8'd90) ? 
                    (X_CENTER + ((mult_x_p2 * 32'd3) >> 12)) :
                    (X_CENTER - ((mult_x_p2 * 32'd3) >> 12));
            end else begin
                tar_x_p3 <= (angle_p2 < 8'd90) ? 
                    (X_CENTER + (mult_x_p2 >> 10)) :
                    (X_CENTER - (mult_x_p2 >> 10));
            end

            tar_y_p3 <= Y_CENTER - (mult_y_p2 >> 10);
        end
    end

    // [Stage 4]: 계산 완료된 안전한 좌표를 배열(메모리)에 최종 쓰기
    always_ff @(posedge clk) begin
        if (reset) begin
            radar_tar_vld <= '0;
        end else if (dist_valid_p3) begin
            radar_tar_x[angle_p3]   <= tar_x_p3;
            radar_tar_y[angle_p3]   <= tar_y_p3;
            radar_tar_vld[angle_p3] <= 1'b1;
        end
    end


    // Stage 1 : 기본 연산 및 절대값 계산
    logic [10:0] dx_abs_st1, dy_abs_st1;
    logic [10:0] dx_eval_st1, dy_eval_st1;
    logic [9:0] x_pixel_st1, y_pixel_st1;

    always_ff @(posedge clk) begin
        // 좌표 전달
        x_pixel_st1 <= x_pixel;
        y_pixel_st1 <= y_pixel;

        // 절대값 계산
        dx_abs_st1 <= (x_pixel > X_CENTER) ? (x_pixel - X_CENTER) : (X_CENTER - x_pixel);
        dy_abs_st1 <= (y_pixel < Y_CENTER) ? (Y_CENTER - y_pixel) : 11'd0;

        // 비율 보정
        dx_eval_st1 <= WIDE_MONITOR_FIX ? ((((x_pixel > X_CENTER) ? (x_pixel - X_CENTER) : (X_CENTER - x_pixel)) * 11'd341) >> 8) : 
                                           ((x_pixel > X_CENTER) ? (x_pixel - X_CENTER) : (X_CENTER - x_pixel));
        dy_eval_st1 <= (y_pixel < Y_CENTER) ? (Y_CENTER - y_pixel) : 11'd0;
    end


    // Stage 2: 곱셈 (제곱, 선 계산)
    logic [31:0] r2_now_st2;
    logic [31:0] line_L_st2, line_R_st2;
    logic [9:0] x_pixel_st2, y_pixel_st2;
    logic [10:0] dx_eval_st2;

    always_ff @(posedge clk) begin
        x_pixel_st2 <= x_pixel_st1;
        y_pixel_st2 <= y_pixel_st1;
        dx_eval_st2 <= dx_eval_st1;

        // 제곱 계산 (동심원용)
        r2_now_st2 <= (dx_eval_st1 * dx_eval_st1) + (dy_eval_st1 * dy_eval_st1);

        // 선 계산 (와이퍼용)
        line_L_st2 <= dy_eval_st1 * cos_val;
        line_R_st2 <= dx_eval_st1 * sin_val;
    end


    // Stage 3: 최종 판단 및 출력 (generate 배열 사용)
    localparam int R1 = 80 * 80;
    localparam int R2 = 160 * 160;
    localparam int R3 = 240 * 240;
    localparam int R4 = 320 * 320;

    localparam int THICK1 = 4 * 80;
    localparam int THICK2 = 4 * 160;
    localparam int THICK3 = 4 * 240;
    localparam int THICK4 = 4 * 320;

    // generate 사용
    // pipeline registers
    logic [180:0] dot_hit_reg;   
    logic circle_on_pre, line_on_pre;  // 동기화를 위한 사전 레지스터
    logic [180:0] dot_hit_array;

    genvar i;
    generate
        for (i = 0; i <= 180; i++) begin : gen_dot_hit
            logic [10:0] tx_abs, ty_abs;
            logic hit_cond;

            // 배열 비교는 x_pixel_st2, y_pixel_st2 
            assign tx_abs = (x_pixel_st2 > radar_tar_x[i]) ? (x_pixel_st2 - radar_tar_x[i]) : (radar_tar_x[i] - x_pixel_st2);
            assign ty_abs = (y_pixel_st2 > radar_tar_y[i]) ? (y_pixel_st2 - radar_tar_y[i]) : (radar_tar_y[i] - y_pixel_st2);

            if (WIDE_MONITOR_FIX) begin
                assign hit_cond = ((tx_abs == 11'd0 && ty_abs <= 11'd2) || (tx_abs == 11'd1 && ty_abs <= 11'd1));
            end else begin
                assign hit_cond = ((tx_abs == 11'd0 && ty_abs <= 11'd1) || (tx_abs == 11'd1 && ty_abs == 11'd0));
            end
            always_ff @(posedge clk) begin
                dot_hit_reg[i] <= radar_tar_vld[i] && hit_cond;
            end
        end
    endgenerate

    // 와이퍼 선
    logic side_match, is_90;
    assign side_match = (angle < 8'd90) ? (x_pixel_st2 >= X_CENTER) : (x_pixel_st2 <= X_CENTER);
    assign is_90 = (angle == 8'd90);

    // 최종 플래그 출력 (ff를 거쳐 안정화)
    always_ff @(posedge clk) begin
        // 동심원
        circle_on_pre <= ((r2_now_st2 > (R1 - THICK1)) && (r2_now_st2 < (R1 + THICK1))) ||
                     ((r2_now_st2 > (R2 - THICK2)) && (r2_now_st2 < (R2 + THICK2))) ||
                     ((r2_now_st2 > (R3 - THICK3)) && (r2_now_st2 < (R3 + THICK3))) ||
                     ((r2_now_st2 > (R4 - THICK4)) && (r2_now_st2 < (R4 + THICK4)));




        line_on_pre <= (y_pixel_st2 <= Y_CENTER) && (r2_now_st2 <= R4) && 
                   (is_90 ? (dx_eval_st2 <= 11'd1) : 
                            (side_match && (line_L_st2 + 32'd1500 > line_R_st2) && (line_L_st2 < (line_R_st2 + 32'd1500))));
    end

    // Stage 4 : 181-input OR 병합 및 최종 플래그 출력
    always_ff @(posedge clk) begin
        dot_on    <= |dot_hit_reg;

        circle_on <= circle_on_pre;
        line_on   <= line_on_pre;
    end
endmodule
