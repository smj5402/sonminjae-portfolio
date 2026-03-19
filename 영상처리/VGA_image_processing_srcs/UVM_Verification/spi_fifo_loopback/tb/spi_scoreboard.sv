class spi_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(spi_scoreboard)

    uvm_analysis_imp_tx #(spi_seq_item, spi_scoreboard) tx_ap;
    uvm_analysis_imp_rx #(spi_seq_item, spi_scoreboard) rx_ap;

    // Queue for expected values 
    spi_seq_item expected_q[$];

    int unsigned pass_cnt;
    int unsigned fail_cnt;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        tx_ap = new("tx_ap", this);
        rx_ap = new("rx_ap", this);
    endfunction

    // called by TX monitor 
    function void write_tx(spi_seq_item item);
        expected_q.push_back(item);
        `uvm_info("SCB",
            $sformatf("[TX] pushed expected 0x%02h  (queue=%0d)",
                      item.data, expected_q.size()),
            UVM_HIGH)
    endfunction

    // called by RX monitor 
    function void write_rx(spi_seq_item item);
        spi_seq_item exp;

        if (expected_q.size() == 0) begin
            `uvm_error("SCB",
                $sformatf("[RX] received 0x%02h but expected queue is EMPTY",
                          item.data))
            fail_cnt++;
            return;
        end

        exp = expected_q.pop_front();

        if (item.data === exp.data) begin
            pass_cnt++;
            `uvm_info("SCB",
                $sformatf("PASS  exp=0x%02h  got=0x%02h", exp.data, item.data),
                UVM_MEDIUM)
        end else begin
            fail_cnt++;
            `uvm_error("SCB",
                $sformatf("FAIL  exp=0x%02h  got=0x%02h", exp.data, item.data))
        end
    endfunction

    // final report 
    function void report_phase(uvm_phase phase);
        `uvm_info("SCB", "======== Scoreboard Report ========", UVM_NONE)
        `uvm_info("SCB",
            $sformatf("  PASS: %0d   FAIL: %0d", pass_cnt, fail_cnt),
            UVM_NONE)

        if (expected_q.size() > 0)
            `uvm_error("SCB",
                $sformatf("  %0d item(s) sent but NEVER received by RX monitor",
                          expected_q.size()))

        if (fail_cnt > 0)
            `uvm_error("SCB", "  *** TEST FAILED ***")
        else
            `uvm_info("SCB", "  *** TEST PASSED ***", UVM_NONE)
    endfunction

endclass
