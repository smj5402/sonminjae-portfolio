`timescale 1ns / 1ps

module ultrasonic_sensor (
    input logic clk,
    input logic reset,
    input logic sw,
    input logic i_echo,  // 센서로부터 들어오는 Echo 신호 (비동기)
    input logic [7:0] i_angle,
    output logic o_trig,  // 센서로 나가는 Trigger 신호
    output logic [7:0] o_distance,  // 계산된 거리 (cm)
    output logic o_valid  // 데이터 갱신 완료 알림 (1클럭 펄스)
);

    // tick generator
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

    // 2. FSM 상태 정의
    typedef enum logic [2:0] {
        IDLE,       // 대기 상태
        TRIGGER,    // 10us Trig 펄스 발생
        WAIT_ECHO,  // Echo 신호가 High가 되기를 기다림
        CALC_ECHO,  // Echo가 High인 동안 거리 계산
        DONE        // 계산 완료 및 데이터 출력
    } state_t;

    state_t        state;

    // 3. 내부 카운터 변수들
    logic   [ 9:0] trig_cnt;  // 10us 카운터 (0 ~ 999)
    logic   [12:0] cm_div_cnt;  // 58us 카운터 (0 ~ 5799)
    logic   [ 7:0] cm_cnt;  // cm 누적 카운터

    // 4. 단일 제어 블록 (FSM + Datapath 통합)
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
            // 기본값 (펄스 신호 초기화)
            o_valid <= 0;

            case (state)
                IDLE: begin
                    o_trig     <= 0;
                    trig_cnt   <= 0;
                    cm_div_cnt <= 0;
                    cm_cnt     <= 0;
                    timeout_cnt <= 0;
                    // 시작 신호가 들어오면 트리거 상태로 이동
                    // if (tick) begin
                    if(start_trigger) state <= TRIGGER;
                    // if (angle_changed) begin
                    //     state <= TRIGGER;
                    // end else if(tick) begin
                    //     state <= TRIGGER;
                    // end
                end

                TRIGGER: begin
                    o_trig <= 1;  // Trig High 유지
                    if (trig_cnt == 1000 - 1) begin
                        o_trig   <= 0; // 10us 달성 시 Low로 내림
                        trig_cnt <= 0;
                        state    <= WAIT_ECHO;
                    end else begin
                        trig_cnt <= trig_cnt + 1;
                    end
                end

                WAIT_ECHO: begin
                    // 동기화된 Echo 신호가 High로 올라가면 계산 시작
                    if (echo_sync2) begin
                        state <= CALC_ECHO;
                        timeout_cnt <= 0;
                    end else if (timeout_cnt >= 3_000_000 || angle_changed) begin
                        cm_cnt <= 8'd0; // 측정 실패 시 거리를 0으로 보고
                        state  <= DONE; // 강제로 DONE으로 이동하여 o_valid 발생
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

                            // [수정된 부분] 255를 넘어가면 0으로 돌아가지 않도록 막음 (Overflow 방지)
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
                    o_distance <= cm_cnt; // 최종 계산값을 출력 레지스터에 저장
                    o_valid    <= 1;      // FND나 제어기에 "데이터 준비됨"을 1클럭 펄스로 알림
                    state      <= IDLE;   // 다음 측정을 위해 대기 상태로 복귀
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule
