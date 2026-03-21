`timescale 1ns / 1ps

module Detecing_Moving (
    input  logic        clk,
    reset,
    de,
    vsync,
    input  logic        btnU,
    btnD,
    btnL,
    btnR,
    input  logic [16:0] addr,
    input  logic [11:0] i_scharr,
    input  logic        pixel_C,
    pixel_B,
    pixel_A,
    output logic [11:0] detected_scahrr
);


    logic motion_raw;
    assign motion_raw = (pixel_C != pixel_B) && (pixel_B != pixel_A);

    logic [319:0] lb0, lb1;
    logic [2:0] r0, r1, r2;

    logic [16:0] addr_d1;
    logic [11:0] i_scharr_d1;
    logic        pixel_C_d1;
    logic [ 3:0] density_cnt;

    (* ram_style = "block" *)logic [ 3:0] ghost_ram   [0:76800-1];
    logic [3:0] curr_life, next_life;
    logic vsync_d1, age_en;


    typedef enum logic [2:0] {
        NEXT_LIFE0,
        NEXT_LIFE3,
        NEXT_LIFE7,
        NEXT_LIFE11,
        NEXT_LIFE15
    } state_next_life;


    typedef enum logic [2:0] {
        DENSITY_CNT0,
        DENSITY_CNT3,
        DENSITY_CNT7,
        DENSITY_CNT11,
        DENSITY_CNT15
    } state_density_cnt;


    state_next_life next_life_curr, next_life_next;
    state_density_cnt density_cnt_curr, density_cnt_next;
    logic [3:0] set_next_life;
    logic [3:0] set_density_cnt;

    always_ff @(posedge clk) begin
        if (reset) begin
            {lb0, lb1}   <= 0;
            {r0, r1, r2} <= 0;
        end else if (de) begin
            lb0         <= {lb0[318:0], motion_raw};
            lb1         <= {lb1[318:0], lb0[319]};
            r2          <= {r2[1:0], motion_raw};
            r1          <= {r1[1:0], lb0[319]};
            r0          <= {r0[1:0], lb1[319]};

            addr_d1     <= addr;
            i_scharr_d1 <= i_scharr;
            pixel_C_d1  <= pixel_C;

            curr_life   <= ghost_ram[addr];

        end
    end

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            vsync_d1 <= 0;
            age_en   <= 0;
        end else begin
            vsync_d1 <= vsync;
            if (vsync && !vsync_d1) age_en <= 1;
            else if (de && addr == 17'd76799) age_en <= 0;
        end
    end

    logic btnU_d, btnD_d, btnL_d, btnR_d;
    logic btnU_edge, btnD_edge, btnL_edge, btnR_edge;

    always_ff @(posedge clk) begin
        btnU_d <= btnU;
        btnD_d <= btnD;
        btnL_d <= btnL;
        btnR_d <= btnR;
    end


    assign btnU_edge = (btnU && !btnU_d);
    assign btnD_edge = (btnD && !btnD_d);
    assign btnL_edge = (btnL && !btnL_d);
    assign btnR_edge = (btnR && !btnR_d);

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            next_life_curr   <= NEXT_LIFE7;
            density_cnt_curr <= DENSITY_CNT7;
        end else begin

            next_life_curr   <= next_life_next;
            density_cnt_curr <= density_cnt_next;

        end
    end
    always_comb begin
        next_life_next = next_life_curr;
        set_next_life  = 4'd7;
        case (next_life_curr)
            NEXT_LIFE0: begin
                set_next_life = 4'd0;
                if (btnU_edge) next_life_next = NEXT_LIFE3;
            end
            NEXT_LIFE3: begin
                set_next_life = 4'd3;
                if (btnU_edge) next_life_next = NEXT_LIFE7;
                else if (btnD_edge) next_life_next = NEXT_LIFE0;
            end
            NEXT_LIFE7: begin
                set_next_life = 4'd7;
                if (btnU_edge) next_life_next = NEXT_LIFE11;
                else if (btnD_edge) next_life_next = NEXT_LIFE3;

            end
            NEXT_LIFE11: begin
                set_next_life = 4'd11;
                if (btnU_edge) next_life_next = NEXT_LIFE15;
                else if (btnD_edge) next_life_next = NEXT_LIFE7;

            end
            NEXT_LIFE15: begin
                set_next_life = 4'd15;
                if (btnD_edge) next_life_next = NEXT_LIFE11;

            end
            default: begin
                next_life_next = next_life_curr;
                set_next_life  = 4'd3;

            end
        endcase

    end


    always_comb begin
        density_cnt_next = density_cnt_curr;
        set_density_cnt  = 4'd7;
        case (density_cnt_curr)
            DENSITY_CNT0: begin
                set_density_cnt = 4'd0;
                if (btnR_edge) density_cnt_next = DENSITY_CNT3;
            end
            DENSITY_CNT3: begin
                set_density_cnt = 4'd3;
                if (btnR_edge) density_cnt_next = DENSITY_CNT7;
                else if (btnL_edge) density_cnt_next = DENSITY_CNT0;
            end
            DENSITY_CNT7: begin
                set_density_cnt = 4'd7;
                if (btnR_edge) density_cnt_next = DENSITY_CNT11;
                else if (btnL_edge) density_cnt_next = DENSITY_CNT3;

            end
            DENSITY_CNT11: begin
                set_density_cnt = 4'd11;
                if (btnR_edge) density_cnt_next = DENSITY_CNT15;
                else if (btnL_edge) density_cnt_next = DENSITY_CNT7;

            end
            DENSITY_CNT15: begin
                set_density_cnt = 4'd15;
                if (btnL_edge) density_cnt_next = DENSITY_CNT11;

            end
            default: begin
                density_cnt_next = density_cnt_curr;
                set_density_cnt  = 4'd3;

            end
        endcase
    end

    //밀도 판별 
    always_comb begin
        density_cnt = r0[0]+r0[1]+r0[2] + r1[0]+r1[1]+r1[2] + r2[0]+r2[1]+r2[2];

        if (density_cnt >= set_density_cnt && pixel_C_d1)
            next_life = set_next_life;  // 감지 시 충전
        else if (age_en && curr_life > 0)
            next_life = curr_life - 4'd1;  // 에이징
        else next_life = curr_life;
    end

    always_ff @(posedge clk) begin
        if (de) begin
            ghost_ram[addr_d1] <= next_life;
        end
    end

    always_comb begin
        if (curr_life > 0) detected_scahrr = {4'h0, curr_life, 4'h0};
        else detected_scahrr = i_scharr_d1;
    end
endmodule
