`timescale 1ns / 1ps
module tb_spi_top;

    reg        clk;
    reg        reset;
    reg        m_start;
    reg  [7:0] m_tx_data;
    wire       m_tx_ready;
    wire [7:0] m_rx_data;
    wire       m_done;
    reg  [7:0] s_tx_data;
    wire [7:0] s_rx_data;
    wire       s_done;

    spi_top dut (
        .clk(clk),
        .reset(reset),
        .m_start(m_start),
        .m_tx_data(m_tx_data),
        .m_tx_ready(m_tx_ready),
        .m_rx_data(m_rx_data),
        .m_done(m_done),
        .s_tx_data(s_tx_data),
        .s_rx_data(s_rx_data),
        .s_done(s_done)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        reset = 1;
        m_start = 0;
        m_tx_data = 0;
        s_tx_data = 0;
        
        #50 reset = 0;
        
        #20;
        m_tx_data = 8'hA5;
        s_tx_data = 8'h5A;
        #10 m_start = 1;
        #10 m_start = 0;
        
        @(posedge m_done);
        #20;
        
        $display("Master TX: A5 -> Slave RX: %h %s", s_rx_data, (s_rx_data == 8'hA5) ? "OK" : "FAIL");
        $display("Slave TX: 5A -> Master RX: %h %s", m_rx_data, (m_rx_data == 8'h5A) ? "OK" : "FAIL");
        
        #100 $finish;
    end

endmodule