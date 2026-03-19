module gaussian_filter (
    input  logic       pclk,
    input  logic       reset,
    input  logic       valid_in,
    input  logic       vsync_edge,
    input  logic [7:0] i_gray,
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
            line1_mem[column] <= i_gray; // 방금 사용한 데이터 2층으로기모시기
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

    logic [11:0] sum_stage1;
    logic [11:0] sum_stage2;
    logic v1, v2;
    logic s1, s2;

    // Stage 1: 가중치 곱 + 부분합
    always_ff @(posedge pclk) begin
        if (reset) begin
            sum_stage1 <= 12'd0;
            v1         <= 1'b0;
            s1         <= 1'b0;
        end else begin
            // (p11 + p13 + p31 + p33) * 1
            sum_stage1 <= p11 + p13 + p31 + p33
            // (p12 + p21 + p23 + p32) * 2
            + ((p12 + p21 + p23 + p32) << 1)
            // (p22) * 4
            + (p22 << 2);
            v1 <= valid_in;
            s1 <= vsync_edge;
        end
    end

    // Stage 2: 1/16 
    always_ff @(posedge pclk) begin
        if (reset) begin
            sum_stage2 <= 12'd0;
            o_grey     <= 8'd0;
            valid_out  <= 1'b0;
            vsync_out  <= 1'b0;
        end else begin
            sum_stage2 <= sum_stage1;
            // 1/16 스케일
            o_grey     <= sum_stage1[11:4];
            valid_out  <= v1;
            vsync_out  <= s1;
        end
    end

endmodule
