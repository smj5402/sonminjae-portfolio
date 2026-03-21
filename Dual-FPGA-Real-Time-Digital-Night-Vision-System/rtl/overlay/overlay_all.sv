`timescale 1ns / 1ps

module overlay_all #(
    parameter x_start = 100,
    parameter y_start = 100
    ) (
    input  logic        clk,
    input  logic [ 7:0] distance,
    input  logic [ 7:0] angle,
    input  logic        dist_valid,
    input  logic [ 7:0] x_number, 
    input  logic [ 7:0] y_number, 
    input  logic [ 9:0] x_pixel,
    input  logic [ 9:0] y_pixel,
    input  logic [11:0] i_rgb,
    output logic [11:0] o_rgb
    );


    // 문자 저장 ROM
    logic [7:0] rom [0:176 - 1];

    initial begin
        $readmemh("font_number_rom.mem", rom);
    end


    logic [9:0] tar_x_index, tar_y_index;
    logic [9:0] x_index;
    logic [9:0] font_y_index;
    logic [9:0] dnum_y_index;
    logic [9:0] number1_y_index;
    logic [9:0] number2_y_index;
    
    logic [7:0] font_data;
    logic [7:0] number_data;
    
    logic tar_on, font_on, number_on, frame_on;


    // 과녁 인덱스
    assign tar_x_index = (x_number > 8) ? (x_number - 8) : 0;
    assign tar_y_index = (y_number > 8) ? (y_number - 8) : 0;


    // x 픽셀 인덱스
    assign x_index = (x_pixel - x_start);       // x_index 공통
    // 문자 출력 y 위치 
    assign font_y_index = (y_pixel - y_start);
    assign dnum_y_index = font_y_index - 10;
    // x 숫자 출력 y 위치
    assign number1_y_index = font_y_index - 430;
    // y 숫자 출력 y 위치
    assign number2_y_index = font_y_index - 440;


    // 과녁 띄우는 영역
    logic tar_zone;
    assign tar_zone = (x_pixel >= tar_x_index) && (x_pixel < tar_x_index + 16) &&
                      (y_pixel >= tar_y_index) && (y_pixel < tar_y_index + 16);

    // 문자 띄우는 영역
    logic font_zone;
    assign font_zone = ((x_index >= 0) && (x_index < 128)) &&
                       ((font_y_index >= 0) && (font_y_index < 8));
    logic dnum_zone;
    assign dnum_zone = ((x_index >= 0) && (x_index < 128)) &&
                       ((dnum_y_index >= 0) && (dnum_y_index < 8));

    // X좌표 띄우는 인덱스
    logic number1_zone;
    assign number1_zone = ((x_index >= 0) && (x_index < 128)) &&
                         ((number1_y_index >= 0) && (number1_y_index < 8));
    
    logic number2_zone;
    assign number2_zone = ((x_index >= 0) && (x_index < 128)) &&
                         ((number2_y_index >= 0) && (number2_y_index < 8));


    // 숫자 데이터 연결
    logic [3:0] d_data_1, d_data_10, d_data_100;
    logic [3:0] x_data_1, x_data_10, x_data_100;
    logic [3:0] y_data_1, y_data_10, y_data_100;


    // 문자 출력 영역 내 문자 데이터 자릿수 영역 설정
    logic [3:0] font_pos;
    logic [3:0] num_pos;
    assign font_pos = x_index[6:3];
    assign num_pos  = x_index[6:3];

    logic [7:0] tar_addr;
    logic [7:0] font_addr;
    logic [7:0] number_addr;

    always_comb begin
        case (font_pos)
            4'd8 : font_addr = 8'd10;     // 대문자로 제한
            4'd9 : font_addr = 8'd11;
            4'd10: font_addr = 8'd12;
            4'd11: font_addr = 8'd13;
            4'd12: font_addr = 8'd14;
            4'd13: font_addr = 8'd15;
            4'd14: font_addr = 8'd16;
            4'd15: font_addr = 8'd17;
            default: font_addr = 8'd21;
        endcase

        case (num_pos)
            4'd11 :  number_addr = (dnum_y_index < 10) ? 8'd21      : (number1_y_index < 10) ? 8'd18     : 8'd19;
            4'd12 :  number_addr = (dnum_y_index < 10) ? 8'd21      : 8'd20;
            4'd13 :  number_addr = (dnum_y_index < 10) ? d_data_100 : (number1_y_index < 10) ? x_data_100 : y_data_100;
            4'd14 :  number_addr = (dnum_y_index < 10) ? d_data_10  : (number1_y_index < 10) ? x_data_10  : y_data_10;
            4'd15 :  number_addr = (dnum_y_index < 10) ? d_data_1   : (number1_y_index < 10) ? x_data_1   : y_data_1;
            default: number_addr = 8'd21;
        endcase
    end


    // ROM으로부터 출력 문자에 해당하는 데이터 받아오기
    logic [2:0] current_row;

    assign current_row = font_zone    ? font_y_index[2:0] :
                         dnum_zone    ? dnum_y_index[2:0] :
                         number1_zone ? number1_y_index[2:0] :
                                        number2_y_index[2:0];
                                        

    always_ff @(posedge clk) begin
        // 문자, 타겟
        font_data <= rom[{font_addr, current_row}];

        // 숫자
        number_data <= rom[{number_addr, current_row}];
    end

    // ------------- 색상 덮어씌울 영역 -------------------------

    always_comb begin
        font_on   = 1'b0;
        number_on = 1'b0;

        // 문자 출력 영역 && 문자 형상 구현 영역
        font_on = font_zone && font_data[7 - (x_index[2:0])];
        // 숫자 출력 영역 && 숫자 형상 구현 영역
        number_on = (dnum_zone || number1_zone || number2_zone) && number_data[7 - (x_index[2:0])];
    end


    //테두리
    assign frame_on = ((x_pixel >= 0) && (x_pixel < 4) || ((x_pixel >= 635) && (x_pixel < 640))) ||
                      ((y_pixel >= 0) && (y_pixel < 5) || ((y_pixel >= 476) && (y_pixel < 480)));

    // --------------------------------------------------------

    logic dot_on, line_on, circle_on, radar_frame_on;

    // 최종 출력 (색상 지정)
    always_comb begin
        if (frame_on) begin
            o_rgb = 12'hFFF;
        end else if (dot_on) begin
            o_rgb = 12'hF00;
        end else if (line_on || circle_on)begin
            o_rgb = 12'h0F0;
        end else if (radar_frame_on) begin
            o_rgb = 12'h000;
        end else if (tar_on & tar_zone) begin
            o_rgb = 12'hF00;
        end else if(font_on) begin
            o_rgb = 12'hFF0;
        end else if (number_on) begin
            o_rgb = 12'hFF0;
        end else
            o_rgb = i_rgb;
    end

    // 타겟 출력용
    target_overlay (
        .x_offset (x_pixel - tar_x_index),
        .y_offset (y_pixel - tar_y_index),
        .target_on(tar_on)
    );


    // 레이더 출력용
    radar U_RADER(
        .clk            (clk),
        .distance       (distance),
        .angle          (angle),
        .dist_valid     (dist_valid),
        .x_pixel        (x_pixel),
        .y_pixel        (y_pixel),
        .dot_on         (dot_on),
        .line_on        (line_on),
        .circle_on      (circle_on),
        .radar_frame_on (radar_frame_on)
    );


    // 숫자 연산용
    BCD_Convert U_distance_BCD (
        .data_in       (distance),
        .data_1        (d_data_1),
        .data_10       (d_data_10),
        .data_100      (d_data_100)
    );

    BCD_Convert U_x_coord(
        .data_in      (x_number),
        .data_1       (x_data_1),
        .data_10      (x_data_10),
        .data_100     (x_data_100)
    );

    BCD_Convert U_y_coord(
        .data_in      (y_number),
        .data_1       (y_data_1),
        .data_10      (y_data_10),
        .data_100     (y_data_100)
    );

endmodule



module BCD_Convert (
    input  logic [7:0] data_in,
    output logic [3:0] data_1,
    output logic [3:0] data_10,
    output logic [3:0] data_100
);

    assign data_1 = data_in % 10;
    assign data_10 = (data_in / 10) % 10;
    assign data_100 = (data_in / 100) % 10;

endmodule


module target_overlay (
    input  logic [3:0] x_offset, // 0~15
    input  logic [3:0] y_offset, // 0~15
    output logic       target_on
);

    logic [15:0] target_row;

    always_comb begin
        case (y_offset)
            4'h0, 4'h1: target_row = 16'h0180; // 상단 수직선
            4'h2:       target_row = 16'h0FF0; // 원 상단
            4'h3:       target_row = 16'h1818; 
            4'h4, 4'h5: target_row = 16'h2004;
            4'h6:       target_row = 16'h4002;
            4'h7, 4'h8: target_row = 16'hFDBF; // 중앙 수평선 + 조준점
            4'h9:       target_row = 16'h4002;
            4'hA, 4'hB: target_row = 16'h2004;
            4'hC:       target_row = 16'h1818;
            4'hD:       target_row = 16'h0FF0; // 원 하단
            4'hE, 4'hF: target_row = 16'h0180; // 하단 수직선
            default: target_row = 16'h0000;
        endcase
    end

    assign target_on = target_row[4'd15 - x_offset];

endmodule


module radar (
    input  logic        clk,
    input  logic [ 7:0] distance,
    input  logic [ 7:0] angle,
    input  logic        dist_valid,
    input  logic [ 9:0] x_pixel,
    input  logic [ 9:0] y_pixel,
    output logic        dot_on,
    output logic        line_on,
    output logic        circle_on,
    output logic        radar_frame_on
);

    localparam x_frame_index = 0;
    localparam y_frame_index = 360;
    localparam WIDTH         = 160;
    localparam HEIGHT        = 120;
    localparam FRAME         = 4;

    localparam x_center = x_frame_index + (WIDTH / 2);
    localparam y_center = y_frame_index + HEIGHT - FRAME;

    assign radar_frame_on = (x_pixel >= x_frame_index && x_pixel < x_frame_index + WIDTH) &&
                            (y_pixel >= y_frame_index && y_pixel < y_frame_index + HEIGHT);

    logic [19:0] sin_cos_mem [0:89];
    initial begin
        $readmemh("sin_cos_table.mem", sin_cos_mem);
    end

    logic [6:0] rom_addr;
    logic [9:0] sin, cos; // 부호 없는 절댓값
    logic [19:0] rom_data;

    assign rom_addr = (angle >= 90) ? (179 - angle) : angle;
    assign rom_data = sin_cos_mem[rom_addr];
    assign sin  = rom_data[19:10];
    assign cos  = rom_data[9:0];

    // 빨간 점 좌표 계산
    logic [9:0] radar_tar_x [0:179];
    logic [9:0] radar_tar_y [0:179];
    logic [179:0] radar_tar_vld;

    // 중간 계산값
    logic [31:0] x_delta, y_delta; 
    assign x_delta = (distance * 72 * cos) >> 18;
    assign y_delta = (distance * 72 * sin) >> 18;

    always_ff @(posedge clk) begin
        if (dist_valid) begin
            if (distance > 5 && distance < 250) begin
                if (angle < 90)
                    radar_tar_x[angle] <= x_center + x_delta[9:0];
                else
                    radar_tar_x[angle] <= x_center - x_delta[9:0];
                
                radar_tar_y[angle]   <= y_center - y_delta[9:0];
                radar_tar_vld[angle] <= 1'b1;
            end else begin
                radar_tar_vld[angle] <= 1'b0;
            end
        end
    end

    // 레이더 영역
    logic radar_zone;
    assign radar_zone = (x_pixel >= x_frame_index + FRAME && x_pixel < x_frame_index + WIDTH  - FRAME) &&
                        (y_pixel >= y_frame_index + FRAME && y_pixel < y_frame_index + HEIGHT - FRAME);

    // 동심원(윤회안)
    logic [19:0] rinnegan;
    assign rinnegan  = (x_pixel - x_center) * (x_pixel - x_center) + (y_pixel - y_center) * (y_pixel - y_center);
    assign circle_on = radar_zone && ((rinnegan > 600 && rinnegan < 650) ||
                                    (rinnegan > 2450 && rinnegan < 2550) ||
                                    (rinnegan > 5550 && rinnegan < 5700));

    // 와이퍼 선 (절댓값 비교)
    logic [9:0]  x_dist;
    logic [9:0]  y_dist;
    logic [31:0] line_L, line_R;
    logic        side_match;

    // 현재 픽셀과 중심점 사이의 거리(절댓값)
    assign x_dist = (x_pixel > x_center) ? (x_pixel - x_center) : (x_center - x_pixel);
    assign y_dist = (y_center > y_pixel) ? (y_center - y_pixel) : 0;

    // 각도와 픽셀의 위치가 같은 사분면에 있는지 확인
    assign side_match = (angle < 90) ? (x_pixel >= x_center) : (x_pixel <= x_center);

    assign line_L = y_dist * cos; 
    assign line_R = x_dist * sin;

    assign line_on = radar_zone && side_match && (y_pixel < y_center) &&
                      (line_L > line_R - 800) && (line_L < line_R + 800);

    // 빨간 점 출력
    always_comb begin
        dot_on = 1'b0;
        if (radar_zone) begin
            for (int i = 0; i < 180; i++) begin
                if (radar_tar_vld[i] && (x_pixel >= radar_tar_x[i] - 2 && x_pixel <= radar_tar_x[i] + 2)
                                     && (y_pixel >= radar_tar_y[i] - 2 && y_pixel <= radar_tar_y[i] + 2))
                    dot_on = 1'b1;
            end
        end
    end
endmodule
