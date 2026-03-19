module morphology_filter (
    input  logic       pclk,
    input  logic       reset,
    input  logic       valid_in,
    input  logic       vsync_edge,
    input  logic       mode,        // 1: dilation(max), 0: erosion(min)
    input  logic [7:0] i_gray,
    output logic       valid_out,
    output logic       vsync_out,
    output logic [7:0] o_pixel
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

    // 2‑stage pipeline
    logic [7:0] row1_val, row2_val, row3_val;
    logic v1, v2;
    logic s1, s2;

    // Stage 1: 각 행(row)에서 min/max
    always_ff @(posedge pclk) begin
        if (reset) begin
            row1_val <= 8'd0;
            row2_val <= 8'd0;
            row3_val <= 8'd0;
            v1       <= 1'b0;
            s1       <= 1'b0;
        end else begin
            v1 <= valid_in;
            s1 <= vsync_edge;

            if (mode) begin
                // Dilation (max)
                row1_val <= (p11 > p12) ? ((p11 > p13) ? p11 : p13)
                                        : ((p12 > p13) ? p12 : p13);
                row2_val <= (p21 > p22) ? ((p21 > p23) ? p21 : p23)
                                        : ((p22 > p23) ? p22 : p23);
                row3_val <= (p31 > p32) ? ((p31 > p33) ? p31 : p33)
                                        : ((p32 > p33) ? p32 : p33);
            end else begin
                // Erosion (min)
                row1_val <= (p11 < p12) ? ((p11 < p13) ? p11 : p13)
                                        : ((p12 < p13) ? p12 : p13);
                row2_val <= (p21 < p22) ? ((p21 < p23) ? p21 : p23)
                                        : ((p22 < p23) ? p22 : p23);
                row3_val <= (p31 < p32) ? ((p31 < p33) ? p31 : p33)
                                        : ((p32 < p33) ? p32 : p33);
            end
        end
    end

    // Stage 2: 세 행 값에서 최종 min/max
    always_ff @(posedge pclk) begin
        if (reset) begin
            o_pixel   <= 8'd0;
            valid_out <= 1'b0;
            vsync_out <= 1'b0;
        end else begin
            v2        <= v1;
            s2        <= s1;
            valid_out <= v1;
            vsync_out <= s1;

            if (mode) begin
                // Dilation (max)
                o_pixel <= (row1_val > row2_val) ? 
                           ((row1_val > row3_val) ? row1_val : row3_val) :
                           ((row2_val > row3_val) ? row2_val : row3_val);
            end else begin
                // Erosion (min)
                o_pixel <= (row1_val < row2_val) ? 
                           ((row1_val < row3_val) ? row1_val : row3_val) :
                           ((row2_val < row3_val) ? row2_val : row3_val);
            end
        end
    end

endmodule
