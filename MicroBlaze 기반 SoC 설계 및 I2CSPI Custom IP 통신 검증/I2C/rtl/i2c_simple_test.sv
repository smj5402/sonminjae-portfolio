`timescale 1ns / 1ps
module i2c_ascii_test (
    input  logic clk,
    input  logic reset,
    input  logic sw,
    output logic scl,
    inout  wire  sda
);
    logic       i2c_en;
    logic       i2c_start;
    logic       i2c_stop;
    logic [7:0] tx_data;
    logic       tx_done;
    logic       tx_ready;
    
    logic fake_ack;
    assign fake_ack = (U_I2C_MASTER.state == U_I2C_MASTER.ACK1 ||
                       U_I2C_MASTER.state == U_I2C_MASTER.ACK2 ||
                       U_I2C_MASTER.state == U_I2C_MASTER.ACK3 ||
                       U_I2C_MASTER.state == U_I2C_MASTER.ACK4);
    
    assign sda = fake_ack ? 1'b0 : 1'bz;

    i2c_master U_I2C_MASTER (
        .clk      (clk),
        .reset    (reset),
        .i2c_en   (i2c_en),
        .i2c_start(i2c_start),
        .i2c_stop (i2c_stop),
        .tx_data  (tx_data),
        .tx_done  (tx_done),
        .tx_ready (tx_ready),
        .rx_data  (),
        .rx_done  (),
        .scl      (scl),
        .sda      (sda)
    );

    typedef enum logic [2:0] {
        S_IDLE,
        S_START,
        S_WAIT_DATA1,
        S_WAIT_DONE,
        S_DELAY
    } state_t;
    
    state_t state;
    assign i2c_start = 1'b0;
    logic [27:0] delay_counter;
    logic [7:0]  ascii_char;
    localparam DELAY_MAX = 28'd50_000_000;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            state         <= S_IDLE;
            delay_counter <= 0;
            ascii_char    <= 8'h30;
            i2c_en        <= 1'b0;
            i2c_stop      <= 1'b0;
            tx_data       <= 8'h00;
        end else begin
            case (state)
                S_IDLE: begin
                    i2c_en   <= 1'b0;
                    i2c_stop <= 1'b0;
                    if (sw) begin
                        state <= S_START;
                    end
                end
                S_START: begin
                    tx_data  <= {7'h50, 1'b0};  // 0xA0
                    i2c_en   <= 1'b1;
                    i2c_stop <= 1'b0;
                    state    <= S_WAIT_DATA1;
                end
                S_WAIT_DATA1: begin
                    i2c_en <= 1'b0;
                    tx_data <= ascii_char;
                    if (U_I2C_MASTER.state == U_I2C_MASTER.DATA1 && 
                        U_I2C_MASTER.is_address_phase_reg == 1'b0) begin
                        // tx_data  <= ascii_char;
                        i2c_stop <= 1'b1;
                        state    <= S_WAIT_DONE;
                    end
                end
                S_WAIT_DONE: begin
                    if (tx_done) begin
                        i2c_stop <= 1'b0;
                        state    <= S_DELAY;
                        if (ascii_char == 8'h7A) begin
                            ascii_char <= 8'h30;
                        end else begin
                            ascii_char <= ascii_char + 1;
                        end
                    end
                end
                S_DELAY: begin
                    if (delay_counter == DELAY_MAX - 1) begin
                        delay_counter <= 0;
                        state <= sw ? S_START : S_IDLE;
                    end else begin
                        delay_counter <= delay_counter + 1;
                    end
                end
                default: state <= S_IDLE;
            endcase
        end
    end
endmodule