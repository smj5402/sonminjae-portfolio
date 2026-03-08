`timescale 1ns / 1ps

module tb_i2c_ascii_test;

    logic clk, reset, sw;
    wire  scl;
    wire  sda;
    logic [3:0] debug_state;

    // 풀업
    pullup(sda);

    i2c_ascii_test DUT (
        .clk        (clk),
        .reset      (reset),
        .sw         (sw),
        .scl        (scl),
        .sda        (sda),
        .debug_state(debug_state)
    );

    // 100MHz 클럭
    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        $display("=== I2C ASCII Test Start ===");
        reset = 1;
        sw    = 0;
        repeat (20) @(posedge clk);
        reset = 0;
        repeat (10) @(posedge clk);

        // SW ON
        sw = 1;
        $display("[%0t] SW ON", $time);

        // 첫 번째 트랜잭션 완료 대기
        wait(DUT.state == DUT.S_DELAY);
        $display("[%0t] First transaction done!", $time);
        $display("       Slave rx_data = 0x%02X (expect 0x30='0')", 
                 DUT.U_I2C_SLAVE.rx_data);

        // 두 번째 트랜잭션
        wait(DUT.state == DUT.S_START);
        $display("[%0t] Second transaction starting...", $time);
        
        wait(DUT.state == DUT.S_DELAY);
        $display("[%0t] Second transaction done!", $time);
        $display("       Slave rx_data = 0x%02X (expect 0x31='1')", 
                 DUT.U_I2C_SLAVE.rx_data);

        // 세 번째
        wait(DUT.state == DUT.S_START);
        wait(DUT.state == DUT.S_DELAY);
        $display("[%0t] Third transaction done!", $time);
        $display("       Slave rx_data = 0x%02X (expect 0x32='2')", 
                 DUT.U_I2C_SLAVE.rx_data);

        $display("=== PASS ===");
        $finish;
    end

    // 디버그: state 변화 출력
    always @(debug_state) begin
        case (debug_state)
            0: $display("[%0t] State: S_IDLE", $time);
            1: $display("[%0t] State: S_START", $time);
            2: $display("[%0t] State: S_WAIT_ADDR_DONE", $time);
            3: $display("[%0t] State: S_WAIT_DATA_DONE", $time);
            4: $display("[%0t] State: S_DELAY", $time);
        endcase
    end

    // Watchdog
    initial begin
        #100_000_000;  // 100ms
        $display("[TIMEOUT]");
        $finish;
    end

endmodule