`timescale 1ns / 1ps

module overlay_all #(
    parameter x_start = 100,
    parameter y_start = 100
) (
    input  logic        clk,
    input  logic [ 7:0] distance,
    input  logic [ 7:0] x_number,
    input  logic [ 7:0] y_number,
    input  logic [ 9:0] x_pixel,
    input  logic [ 9:0] y_pixel,
    input  logic [11:0] i_rgb,
    output logic [11:0] o_rgb
);


    // 문자 저장 ROM
    logic [7:0] rom[0:176 - 1];

    initial begin
        $readmemh("ascii_rom.mem", rom);
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
    assign tar_x_index     = (x_number > 8) ? (x_number - 8) : 0;
    assign tar_y_index     = (y_number > 8) ? (y_number - 8) : 0;


    // x 픽셀 인덱스
    assign x_index         = (x_pixel - x_start);
    // 문자 출력 y 위치 
    assign font_y_index    = (y_pixel - y_start);
    assign dnum_y_index    = font_y_index - 10;
    // x 숫자 출력 y 위치
    assign number1_y_index = font_y_index - 430;
    // y 숫자 출력 y 위치
    assign number2_y_index = font_y_index - 440;


    // 과녁 
    logic tar_zone;
    assign tar_zone = (x_pixel >= tar_x_index) && (x_pixel < tar_x_index + 16) &&
                      (y_pixel >= tar_y_index) && (y_pixel < tar_y_index + 16);

    // 문자 
    logic font_zone;
    assign font_zone = ((x_index >= 0) && (x_index < 128)) &&
                       ((font_y_index >= 0) && (font_y_index < 8));
    logic dnum_zone;
    assign dnum_zone = ((x_index >= 0) && (x_index < 128)) &&
                       ((dnum_y_index >= 0) && (dnum_y_index < 8));

    // X좌표 
    logic number1_zone;
    assign number1_zone = ((x_index >= 0) && (x_index < 128)) &&
                         ((number1_y_index >= 0) && (number1_y_index < 8));

    logic number2_zone;
    assign number2_zone = ((x_index >= 0) && (x_index < 128)) &&
                         ((number2_y_index >= 0) && (number2_y_index < 8));


    // 숫자 데이터
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
            4'd8 : font_addr = 8'd10;     
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
            4'd11:
            number_addr = (dnum_y_index < 10) ? 8'd21      : (number1_y_index < 10) ? 8'd18     : 8'd19;
            4'd12: number_addr = (dnum_y_index < 10) ? 8'd21 : 8'd20;
            4'd13:
            number_addr = (dnum_y_index < 10) ? d_data_100 : (number1_y_index < 10) ? x_data_100 : y_data_100;
            4'd14:
            number_addr = (dnum_y_index < 10) ? d_data_10  : (number1_y_index < 10) ? x_data_10  : y_data_10;
            4'd15:
            number_addr = (dnum_y_index < 10) ? d_data_1   : (number1_y_index < 10) ? x_data_1   : y_data_1;
            default: number_addr = 8'd21;
        endcase
    end


    // 출력 문자를 위한 ROM
    logic [2:0] current_row;

    assign current_row = font_zone    ? font_y_index[2:0] :
                         dnum_zone    ? dnum_y_index[2:0] :
                         number1_zone ? number1_y_index[2:0] :
                                        number2_y_index[2:0];


    always_ff @(posedge clk) begin
        // 문자, 타겟
        font_data   <= rom[{font_addr, current_row}];

        // 숫자
        number_data <= rom[{number_addr, current_row}];
    end


    always_comb begin
        font_on = 1'b0;
        number_on = 1'b0;

        // 문자 출력 영역 & 문자  구현 영역
        font_on = font_zone && font_data[7-(x_index[2:0])];
        // 숫자 출력 영역 & 숫자  구현 영역
        number_on = (dnum_zone) && number_data[7 - (x_index[2:0])];
    end


    // frame
    assign frame_on = ((x_pixel >= 0) && (x_pixel < 4) || ((x_pixel >= 636) && (x_pixel < 640))) ||
                      ((y_pixel >= 0) && (y_pixel < 4) || ((y_pixel >= 476) && (y_pixel < 480)));



    // output 
    always_comb begin
         if (font_on) begin
            o_rgb = 12'hFF0;
        end else if (number_on) begin
            o_rgb = 12'hFF0;
        end else if (frame_on) begin
            o_rgb = 12'hFFF;
        end else o_rgb = i_rgb;
    end

    // 타겟 출력용
    target_overlay u_target_overlay (
        .x_offset (x_pixel - tar_x_index),
        .y_offset (y_pixel - tar_y_index),
        .target_on(tar_on)
    );


    // 숫자 연산용
    BCD_Convert U_distance_BCD (
        .data_in (distance),
        .data_1  (d_data_1),
        .data_10 (d_data_10),
        .data_100(d_data_100)
    );

    BCD_Convert U_x_coord (
        .data_in (x_number),
        .data_1  (x_data_1),
        .data_10 (x_data_10),
        .data_100(x_data_100)
    );

    BCD_Convert U_y_coord (
        .data_in (y_number),
        .data_1  (y_data_1),
        .data_10 (y_data_10),
        .data_100(y_data_100)
    );

endmodule



module BCD_Convert (
    input  logic [7:0] data_in,
    output logic [3:0] data_1,
    output logic [3:0] data_10,
    output logic [3:0] data_100
);

    // [19:16] 100의 자리, [15:12] 10의 자리, [11:8] 1의 자리, [7:0] 입력 데이터
    logic [19:0] bcd;
    integer i;

    always_comb begin
        bcd = 20'b0;
        bcd[7:0] = data_in;

        for (i = 0; i < 8; i = i + 1) begin

            if (bcd[11:8] >= 5) begin
                bcd[11:8] = bcd[11:8] + 3;
            end
            if (bcd[15:12] >= 5) begin
                bcd[15:12] = bcd[15:12] + 3;
            end
            if (bcd[19:16] >= 5) begin
                bcd[19:16] = bcd[19:16] + 3;
            end

            bcd = bcd << 1;
        end
    end

    assign data_1   = bcd[11:8];
    assign data_10  = bcd[15:12];
    assign data_100 = bcd[19:16];

endmodule

module target_overlay (
    input  logic [3:0] x_offset,  // 0~15
    input  logic [3:0] y_offset,  // 0~15
    output logic       target_on
);

    logic [15:0] target_row;

    always_comb begin
        case (y_offset)
            4'h0, 4'h1: target_row = 16'h0180;  // 상단 수직선
            4'h2:       target_row = 16'h0FF0;  // 원 상단
            4'h3:       target_row = 16'h1818;
            4'h4, 4'h5: target_row = 16'h2004;
            4'h6:       target_row = 16'h4002;
            4'h7, 4'h8: target_row = 16'hFDBF;  // 중앙 수평선 + 조준점
            4'h9:       target_row = 16'h4002;
            4'hA, 4'hB: target_row = 16'h2004;
            4'hC:       target_row = 16'h1818;
            4'hD:       target_row = 16'h0FF0;  // 원 하단
            4'hE, 4'hF: target_row = 16'h0180;  // 하단 수직선
            default:    target_row = 16'h0000;
        endcase
    end

    assign target_on = target_row[4'd15-x_offset];

endmodule

