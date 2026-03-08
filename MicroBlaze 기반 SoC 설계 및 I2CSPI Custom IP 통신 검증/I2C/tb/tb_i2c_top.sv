
`timescale 1ns / 1ps
module tb_i2c_simple;

    logic clk, reset;
    logic m_i2c_en, m_i2c_start, m_i2c_stop;
    logic [7:0] m_tx_data;
    logic m_tx_done, m_tx_ready;
    logic [7:0] s_rx_data;
    logic       s_rx_done;
    logic [6:0] s_device_addr;
    logic       i2c_scl;
    wire        i2c_sda;

    pullup (i2c_sda);

    logic [7:0] m_rx_data;
    logic       m_rx_done;
    logic [7:0] s_tx_data;
    logic s_tx_done, s_tx_ready;

    i2c_top DUT (
        .clk          (clk),
        .reset        (reset),
        .m_i2c_en     (m_i2c_en),
        .m_i2c_start  (m_i2c_start),
        .m_i2c_stop   (m_i2c_stop),
        .m_tx_data    (m_tx_data),
        .m_tx_done    (m_tx_done),
        .m_tx_ready   (m_tx_ready),
        .m_rx_data    (m_rx_data),
        .m_rx_done    (m_rx_done),
        .s_device_addr(s_device_addr),
        .s_tx_data    (s_tx_data),
        .s_rx_data    (s_rx_data),
        .s_tx_done    (s_tx_done),
        .s_tx_ready   (s_tx_ready),
        .s_rx_done    (s_rx_done),
        .i2c_scl      (i2c_scl),
        .i2c_sda      (i2c_sda)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        reset         = 1;
        m_i2c_en      = 0;
        m_i2c_start   = 0;
        m_i2c_stop    = 0;
        m_tx_data     = 8'h00;
        s_device_addr = 7'h4A;
        s_tx_data     = 8'h00;
        repeat (10) @(posedge clk);
        reset = 0;
        repeat (5) @(posedge clk);

        $display("[%0t] STEP1: send addr 0x94", $time);
        @(posedge clk);
        #1;
        m_tx_data = 8'h94;
        m_i2c_en  = 1;
        @(posedge clk);
        #1;
        m_i2c_en = 0;

        
        wait (DUT.U_I2C_Master.state == DUT.U_I2C_Master.ACK1);
        m_tx_data = 8'hA5;  

        wait (DUT.U_I2C_Master.state == DUT.U_I2C_Master.DATA1 && 
          DUT.U_I2C_Master.is_address_phase_reg == 0);  
        m_i2c_stop = 1;  

        @(posedge m_tx_done);
        $display("[%0t] tx_done", $time);
        $display("[%0t] RESULT: s_rx_data=0x%02X", $time, s_rx_data);

        if (s_rx_data === 8'hA5) $display("PASS");
        else $display("FAIL");

        repeat (20) @(posedge clk);
        $finish;
    end

    // watchdog
    initial begin
        #10_000_000;
        $display("[TIMEOUT]");
        $finish;
    end

endmodule
