`timescale 1ns / 1ps

module PingPong_Buffer (
    input  logic                       wclk,
    input  logic                       reset,
    input  logic                       we,
    input  logic [$clog2(320*240)-1:0] wAddr,
    input  logic [                7:0] wData,
    // read side
    input  logic                       rclk,
    input  logic [$clog2(320*240)-1:0] rAddr,
    output logic [                7:0] rData,
    // for debugging
    output logic [                5:0] led
);


    typedef enum {
        W_BUFFER_0,
        W_BUFFER_1,
        W_BUFFER_2
    } w_state_t;

    typedef enum {
        R_BUFFER_0,
        R_BUFFER_1,
        R_BUFFER_2
    } r_state_t;


    w_state_t w_state, w_state_next;
    r_state_t r_state, r_state_next;
    assign led[0] = (w_state == W_BUFFER_0);
    assign led[1] = (w_state == W_BUFFER_1);
    assign led[2] = (w_state == W_BUFFER_2);

    assign led[3] = (r_state == R_BUFFER_0);
    assign led[4] = (r_state == R_BUFFER_1);
    assign led[5] = (r_state == R_BUFFER_2);

    // write state
    always_ff @(posedge wclk or posedge reset) begin
        if (reset) begin
            w_state <= W_BUFFER_0;
        end else begin
            w_state <= w_state_next;
        end
    end

    // read state
    always_ff @(posedge rclk or posedge reset) begin
        if (reset) begin
            r_state <= R_BUFFER_0;
        end else begin
            r_state <= r_state_next;
        end
    end

    logic we_0, we_1, we_2;
    logic [16:0] wAddr_0, wAddr_1, wAddr_2;
    logic [16:0] rAddr_0, rAddr_1, rAddr_2;
    logic [7:0] wData_0, wData_1, wData_2;
    logic [7:0] rData_0, rData_1, rData_2;

    logic write_done_0;
    logic write_done_meta_0, write_done_sync_0;

    logic write_done_1;
    logic write_done_meta_1, write_done_sync_1;

    logic write_done_2;
    logic write_done_meta_2, write_done_sync_2;

    always_ff @(posedge rclk or posedge reset) begin
        if (reset) begin
            write_done_meta_0 <= 0;
            write_done_sync_0 <= 0;
            write_done_meta_1 <= 0;
            write_done_sync_1 <= 0;
            write_done_meta_2 <= 0;
            write_done_sync_2 <= 0;
        end else begin
            write_done_meta_0 <= write_done_0;
            write_done_sync_0 <= write_done_meta_0;

            write_done_meta_1 <= write_done_1;
            write_done_sync_1 <= write_done_meta_1;

            write_done_meta_2 <= write_done_2;
            write_done_sync_2 <= write_done_meta_2;
        end
    end

    // WRITE FSM
    always_comb begin
        we_0         = 0;
        wAddr_0      = 0;
        wData_0      = 0;
        we_1         = 0;
        wAddr_1      = 0;
        wData_1      = 0;
        we_2         = 0;
        wAddr_2      = 0;
        wData_2      = 0;
        write_done_0 = 0;
        write_done_1 = 0;
        write_done_2 = 0;
        w_state_next = w_state;

        case (w_state)
            W_BUFFER_0: begin
                write_done_2 = 1; 
                we_0 = we;
                wAddr_0 = wAddr;
                wData_0 = wData;
                if (wAddr == 320 * 240 - 1) begin
                    w_state_next = W_BUFFER_1;
                end
            end

            W_BUFFER_1: begin
                write_done_0 = 1; 
                we_1 = we;
                wAddr_1 = wAddr;
                wData_1 = wData;
                if (wAddr == 320 * 240 - 1) begin
                    w_state_next = W_BUFFER_2;
                end
            end

            W_BUFFER_2: begin
                write_done_1 = 1; 
                we_2 = we;
                wAddr_2 = wAddr;
                wData_2 = wData;
                if (wAddr == 320 * 240 - 1) begin
                    w_state_next = W_BUFFER_0;
                end
            end
        endcase
    end

    // READ FSM
    always_comb begin
        r_state_next = r_state;
        rAddr_0      = 0;
        rAddr_1      = 0;
        rAddr_2      = 0;
        rData        = 0;

        case (r_state)
            R_BUFFER_0: begin
                rAddr_0 = rAddr;
                rData   = rData_0;

                if (rAddr == 320 * 240 - 1) begin
                    if (write_done_sync_1) begin
                        r_state_next = R_BUFFER_1;
                    end else if (write_done_sync_2) begin
                        r_state_next = R_BUFFER_2;
                    end
                end
            end

            R_BUFFER_1: begin
                rAddr_1 = rAddr;
                rData   = rData_1;

                if (rAddr == 320 * 240 - 1) begin
                    if (write_done_sync_2) begin
                        r_state_next = R_BUFFER_2;
                    end else if (write_done_sync_0) begin
                        r_state_next = R_BUFFER_0;
                    end
                end
            end

            R_BUFFER_2: begin
                rAddr_2 = rAddr;
                rData   = rData_2;

                if (rAddr == 320 * 240 - 1) begin
                    if (write_done_sync_0) begin
                        r_state_next = R_BUFFER_0;
                    end else if (write_done_sync_1) begin
                        r_state_next = R_BUFFER_1;
                    end
                end
            end
        endcase
    end

    frameBuffer u_frameBuffer_0 (
        .wclk (wclk),
        .we   (we_0),
        .wAddr(wAddr_0),
        .wData(wData_0),
        .rclk (rclk),
        .rAddr(rAddr_0),
        .rData(rData_0)
    );

    frameBuffer u_frameBuffer_1 (
        .wclk (wclk),
        .we   (we_1),
        .wAddr(wAddr_1),
        .wData(wData_1),
        .rclk (rclk),
        .rAddr(rAddr_1),
        .rData(rData_1)
    );

    frameBuffer u_frameBuffer_2 (
        .wclk (wclk),
        .we   (we_2),
        .wAddr(wAddr_2),
        .wData(wData_2),
        .rclk (rclk),
        .rAddr(rAddr_2),
        .rData(rData_2)
    );

endmodule


