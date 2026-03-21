`timescale 1ns / 1ps
module servo_motor_controller (
    input logic clk,
    input logic reset,
    input logic sw,
    input logic btnL,
    input logic btnR,
    output logic pwm,
    output logic [7:0] degree
);


    logic btnL_edge, btnR_edge;
    logic btnL_prev, btnR_prev;

    logic [20:0] pwm_cnt;
    logic [ 7:0] pwm_degree;

    logic [19:0] duty_target;

    logic [ 7:0] auto_degree;
    logic [26:0] auto_cnt;
    assign duty_target = 20'd50_000 + ((sw ? pwm_degree : auto_degree) * 20'd1111);
    assign degree = sw ? pwm_degree : auto_degree;

    logic dir;
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            btnL_prev <= 0;
            btnR_prev <= 0;
        end else begin
            btnL_prev <= btnL;
            btnR_prev <= btnR;
        end
    end

    // assign btnL_edge = (!btnL_prev && btnL);
    // assign btnR_edge = (!btnR_prev && btnR);

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            auto_cnt <= 0;
            pwm_degree <= 8'd90;
            auto_degree <= 8'd90;
            dir <= 0;
        end else begin
            if (sw) begin
                if (btnL && (pwm_degree > 8'd0)) begin
                    pwm_degree <= pwm_degree - 1;
                end
                if (btnR && (pwm_degree < 8'd180)) begin
                    pwm_degree <= pwm_degree + 1;
                end

            end else begin
                if (auto_cnt >= 27'd2_000_000 - 1) begin
                    auto_cnt <= 0;
                    if (dir == 1'b0) begin
                        if (auto_degree >= 180) begin
                            dir <= 1'b1;
                            auto_degree <= auto_degree - 1;
                        end else begin
                            auto_degree <= auto_degree + 1;
                        end
                    end else begin
                        if (auto_degree <= 0) begin
                            dir <= 1'b0;
                            auto_degree <= auto_degree + 1;
                        end else begin
                            auto_degree <= auto_degree - 1;
                        end
                    end
                end else begin
                    auto_cnt <= auto_cnt + 1;
                end

            end

        end

    end

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            pwm_cnt <= 0;
        end else begin
            if (pwm_cnt >= 21'd2_000_000 - 1) begin
                pwm_cnt <= 0;
            end else pwm_cnt <= pwm_cnt + 1;
        end
    end

    assign pwm = (pwm_cnt < duty_target);
endmodule
