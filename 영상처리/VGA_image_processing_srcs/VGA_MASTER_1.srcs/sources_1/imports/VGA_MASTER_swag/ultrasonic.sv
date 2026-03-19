`timescale 1ns / 1ps

module ultrasonic_sensor (
    input logic clk,
    input logic reset,
    input logic sw,
    input logic i_echo,  
    input logic [7:0] i_angle,
    output logic o_trig,  
    output logic [7:0] o_distance, 
    output logic o_valid  
);

    logic tick;
    logic [23:0] count_tick;
    logic [7:0] angle_reg;
    wire angle_changed = (i_angle != angle_reg);
    logic [21:0] timeout_cnt;
    
    always_ff @(posedge clk or posedge reset) begin
        if (reset) angle_reg <= 8'd0;
        else       angle_reg <= i_angle;
    end

    assign start_trigger = sw ? tick : angle_changed;

    // tick_gen
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            tick       <= 0;
            count_tick <= 0;
        end else begin
            if (count_tick == 10_000_000 - 1) begin
                tick       <= 1;
                count_tick <= 0;
            end else begin
                tick       <= 0;
                count_tick <= count_tick + 1;
            end
        end
    end

    logic echo_sync1, echo_sync2;
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            echo_sync1 <= 0;
            echo_sync2 <= 0;
        end else begin
            echo_sync1 <= i_echo;
            echo_sync2 <= echo_sync1;
        end
    end

    //  FSM state
    typedef enum logic [2:0] {
        IDLE,       // 대기 상태
        TRIGGER,    // 10us Trig 펄스 발생
        WAIT_ECHO,  // Echo 신호가 High가 되기를 기다림
        CALC_ECHO,  // Echo가 High인 동안 거리 계산
        DONE        // 계산 완료 및 데이터 출력
    } state_t;

    state_t        state;

    // internal counter
    logic   [ 9:0] trig_cnt;    
    logic   [12:0] cm_div_cnt;  
    logic   [ 7:0] cm_cnt;      

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            state      <= IDLE;
            trig_cnt   <= 0;
            cm_div_cnt <= 0;
            cm_cnt     <= 0;
            o_trig     <= 0;
            o_distance <= 0;
            o_valid    <= 0;
        end else begin
            o_valid <= 0;

            case (state)
                IDLE: begin
                    o_trig     <= 0;
                    trig_cnt   <= 0;
                    cm_div_cnt <= 0;
                    cm_cnt     <= 0;
                    timeout_cnt <= 0;
                    if(start_trigger) state <= TRIGGER;
                end

                TRIGGER: begin
                    o_trig <= 1;  
                    if (trig_cnt == 1000 - 1) begin
                        o_trig   <= 0; 
                        trig_cnt <= 0;
                        state    <= WAIT_ECHO;
                    end else begin
                        trig_cnt <= trig_cnt + 1;
                    end
                end

                WAIT_ECHO: begin
                    if (echo_sync2) begin
                        state <= CALC_ECHO;
                        timeout_cnt <= 0;
                    end else if (timeout_cnt >= 3_000_000 || angle_changed) begin
                        cm_cnt <= 8'd0; 
                        state  <= DONE; 
                    end else begin
                        timeout_cnt <= timeout_cnt + 1;
                    end
                end

                CALC_ECHO: begin
                    if (echo_sync2) begin
                        if (timeout_cnt >= 3_000_000) begin
                            cm_cnt <= 8'd0;
                            state  <= DONE;
                        end else if (cm_div_cnt == 5800 - 1) begin
                            cm_div_cnt <= 0;

                            if (cm_cnt < 255) begin
                                cm_cnt <= cm_cnt + 1;
                            end
                            timeout_cnt <= timeout_cnt + 1;
                        end else begin
                            cm_div_cnt <= cm_div_cnt + 1;
                            timeout_cnt <= timeout_cnt + 1;
                        end
                    end else begin
                        state <= DONE;
                    end
                end

                DONE: begin
                    o_distance <= cm_cnt; 
                    o_valid    <= 1;      
                    state      <= IDLE;   
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule
