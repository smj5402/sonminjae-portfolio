`timescale 1ns / 1ps
module tb_i2c_master;

    logic       clk;
    logic       reset;
    logic       i2c_en;
    logic       i2c_start;
    logic       i2c_stop;
    logic [7:0] tx_data;
    logic       tx_done;
    logic       tx_ready;
    logic [7:0] rx_data;
    logic       rx_done;
    logic       scl;
    tri1        sda;

    logic [7:0] slave_send_data = 8'b1010_1010;  // 8'haa

    i2c_master dut (.*);

    always #5 clk = ~clk;

    // ack no error
    assign sda = ((dut.state === dut.ACK1 || dut.state === dut.ACK2 || dut.state === dut.ACK3 || dut.state === dut.ACK4) && dut.is_address_phase_reg) ? 1'b0 :
                ((dut.state === dut.READ_DATA1 || dut.state === dut.READ_DATA2 || dut.state === dut.READ_DATA3 || dut.state === dut.READ_DATA4)) ? slave_send_data[7-dut.bit_counter_reg] :
                1'bz;

    ////////////////////////////////////////// read test
    initial begin
        #0;
        clk       = 0;
        reset     = 1;
        i2c_en    = 0;
        i2c_start = 0;
        i2c_stop  = 0;
        tx_data   = 8'h00;
        #50;
        reset = 0;

        @(posedge clk iff (tx_ready == 1));
        i2c_en  <= 1;
        tx_data <= 8'b101_0101_1;  // addr 0x55 read

        @(posedge clk);
        i2c_en <= 0;

        // Read 1010_1010 
        wait (dut.state == dut.READ_DATA1);

        i2c_stop = 1;

        wait (rx_done == 1);

        #100;
        $finish;
    end




    // ///////////////////////////////////// write test
    // initial begin
    // #0;
    // clk       = 0;
    // reset     = 1;
    // i2c_en    = 0;
    // i2c_start = 0;
    // i2c_stop  = 0;
    // tx_data   = 8'h00;
    // #50;
    // reset = 0;
    // // test start
    // @(posedge clk iff (tx_ready == 1));
    // i2c_en  <= 1;
    // tx_data <= 8'b101_0101_0;  // addr 0x55 write
    // @(posedge clk);
    // i2c_en <= 0;
    // // slave : waiting addr phase 
    // wait (dut.state == dut.ACK1);
    // tx_data = 8'h55;  // 0101_0101
    // wait (dut.state == dut.DATA1);
    // i2c_stop = 1;
    // wait (tx_done == 1);
    // #100;
    // $finish;
    // end



endmodule
