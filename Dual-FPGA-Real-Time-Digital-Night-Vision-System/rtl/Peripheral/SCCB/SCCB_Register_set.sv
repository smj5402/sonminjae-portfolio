`timescale 1ns / 1ps


module SCCB_Register_set(

    input  logic clk,
    input  logic reset,
    output logic scl,
    inout  logic sda
);


    // interface signal
    logic [7:0] tx_data;
    logic       tx_ready;
    logic       tx_done;
    logic       rx_done;

    logic       i2c_en;
    logic       i2c_stop;

    register_set U_REGISTER_SET (
        .clk     (clk),
        .reset   (reset),
        .tx_data (tx_data),
        .tx_done (tx_done),
        .rx_done (),
        .tx_ready(tx_ready),
        .i2c_en  (i2c_en),
        .I2C_stop(i2c_stop)
    );
    i2c_master U_I2C_MASTER (
        .clk      (clk),
        .reset    (reset),
        .I2C_En   (i2c_en),
        .I2C_start(1'b0),
        .I2C_stop (i2c_stop),
        .rw_mode  (1'b0),
        .tx_data  (tx_data),
        .tx_done  (tx_done),
        .tx_ready (tx_ready),
        .rx_data  (),
        .rx_done  (),

        .SCL(scl),
        .SDA(sda)
    );
endmodule

module register_set (
    input  logic       clk,
    input  logic       reset,
    // input  logic       tick,
    output logic [7:0] tx_data,
    input  logic       tx_done,
    input  logic       rx_done,
    input  logic       tx_ready,
    output logic       i2c_en,
    output logic       I2C_stop
);


    logic [15:0] mem[0:75];

    initial begin
        $readmemh("OV7670.mem", mem);
    end


    typedef enum {
        IDLE,

        RESET_DEVICE_ADDR,
        RESET_REGISTER_ADDR,
        RESET_REGISTER_DATA,
        RESET_STOP_WAIT,

        WAIT_30MS,

        SEND_DEVICE_ADDR,
        SEND_REGISTER_ADDR,
        SEND_REGISTER_DATA,

        SEND_STOP_WAIT,
        STOP,
        DONE
    } state_t;

    state_t state, state_next;


    logic [7:0] tx_data_reg, tx_data_next;

    logic [23:0] counter, counter_next;
    logic [6:0] mem_addr, mem_addr_next;
    
    assign tx_data = tx_data_reg;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            state       <= IDLE;
            tx_data_reg <= 0;
            counter     <= 0;
            mem_addr    <= 0;
        end else begin
            state       <= state_next;
            tx_data_reg <= tx_data_next;
            counter     <= counter_next;
            mem_addr    <= mem_addr_next;
        end
    end

    always_comb begin
        state_next    = state;
        tx_data_next  = tx_data_reg;
        counter_next  = counter;
        mem_addr_next = mem_addr;
        i2c_en        = 1'b0;
        I2C_stop      = 1'b0;
        
        case (state)
            IDLE: begin
                i2c_en = 1'b0;
                if(counter == 10_000_000) begin //100 ms대기 , 안정화를 위해서
                    counter_next = 0;
                    tx_data_next = 8'h42;  // Device ADDR 
                    state_next   = RESET_DEVICE_ADDR;
                end else begin
                    counter_next = counter + 1;
                end
            end

            RESET_DEVICE_ADDR: begin
                i2c_en = 1'b1;
                if ((tx_ready | tx_done)) begin
                        tx_data_next = 8'h12;  // Reset Register ADDR 
                    state_next   = RESET_REGISTER_ADDR;
                end
            end

            RESET_REGISTER_ADDR, RESET_REGISTER_DATA: begin
                i2c_en = 1'b1;
                if ((tx_ready | tx_done)) begin

                    if (state == RESET_REGISTER_ADDR) begin
                        tx_data_next = 8'h80;  // Reset Register DATA 
                        state_next   = RESET_REGISTER_DATA;
                    end else begin  //RESET_REGISTER_DATA
                        state_next   = RESET_STOP_WAIT;
                    end

                end
            end

            RESET_STOP_WAIT: begin
                I2C_stop = 1'b1;
                if (tx_ready) state_next = WAIT_30MS; // 마스터가 정지 완료하면 대기 상태
            end

            WAIT_30MS: begin
                if (counter == 3_000_000) begin
                    counter_next = 0;
                    tx_data_next = 8'h42;  // Device addr 42
                    state_next   = SEND_DEVICE_ADDR;
                end else begin
                    counter_next = counter + 1;
                end
            end
            ////////////////DONE RESET, DATASEND START/////////////////// 

            SEND_DEVICE_ADDR: begin
                i2c_en = 1'b1;
                if (tx_ready) begin
                    tx_data_next = mem[mem_addr][15:8];  //register addr 
                    state_next   = SEND_REGISTER_ADDR;
                end
            end

            SEND_REGISTER_ADDR: begin
                i2c_en = 1'b1;
                if (tx_done) begin
                    tx_data_next = mem[mem_addr][7:0];  //register data
                    state_next   = SEND_REGISTER_DATA;
                end
            end

            SEND_REGISTER_DATA: begin
                i2c_en = 1'b1;
                if (tx_done) begin
                    state_next = SEND_STOP_WAIT;
                end
            end

            SEND_STOP_WAIT: begin
                if (tx_done) state_next = STOP; // 원래 ACK부분
                I2C_stop =1'b1;
            end

            STOP: begin
                if(mem_addr == 7'd75)begin  //Reigster addr & data sending done
                    mem_addr_next = 0;
                    state_next = DONE;
                end else begin
                    mem_addr_next = mem_addr + 1;
                    tx_data_next = 8'h42;  // Device addr 42
                    state_next = SEND_DEVICE_ADDR;
                end
            end

            DONE: begin  //ALL Setting done
                i2c_en = 1'b0;
                I2C_stop = 1'b1;
            end

            default: state_next = IDLE;
        endcase
    end
endmodule

