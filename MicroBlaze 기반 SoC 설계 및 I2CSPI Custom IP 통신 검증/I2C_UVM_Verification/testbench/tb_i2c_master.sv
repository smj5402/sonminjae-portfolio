`include "uvm_macros.svh"
import uvm_pkg::*;

`uvm_analysis_imp_decl(_drv)
`uvm_analysis_imp_decl(_mon)

interface I2C_if (
    input bit clk,
    input bit reset
);

    logic       I2C_En;
    logic       I2C_start;
    logic       I2C_stop;
    logic [7:0] tx_data;
    logic       tx_done;
    logic       tx_ready;
    logic [7:0] rx_data;
    logic       rx_done;

    logic       SCL;
    wire        SDA;

    clocking drv_cb @(posedge clk);
        default input #1step output #0;
        output I2C_En, I2C_start, I2C_stop, tx_data;
        input tx_ready, tx_done, rx_data, rx_done, SCL;
        inout SDA;
    endclocking

    clocking mon_cb @(posedge clk);
        default input #1step;
        input I2C_En, I2C_start, I2C_stop, tx_data;
        input tx_ready, tx_done, rx_data, rx_done, SCL;
        input SDA;
    endclocking

    modport drv_mp(clocking drv_cb, input clk, input reset);
    modport mon_mp(clocking mon_cb, input clk, input reset);

endinterface

class i2c_seq_item extends uvm_sequence_item;
    rand logic       I2C_En;
    rand logic       I2C_start;
    rand logic       I2C_stop;
    rand logic [7:0] tx_data;

    logic      [7:0] rx_data;
    logic            tx_done;
    logic            rx_done;
    logic            tx_ready;

    constraint c_default {I2C_En == 1'b1;}

    function new(string name = "i2c_seq_item");
        super.new(name);
    endfunction

    `uvm_object_utils_begin(i2c_seq_item)
        `uvm_field_int(I2C_En, UVM_DEFAULT)
        `uvm_field_int(I2C_start, UVM_DEFAULT)
        `uvm_field_int(I2C_stop, UVM_DEFAULT)
        `uvm_field_int(tx_data, UVM_DEFAULT)
        `uvm_field_int(rx_data, UVM_DEFAULT)
        `uvm_field_int(tx_done, UVM_DEFAULT)
        `uvm_field_int(rx_done, UVM_DEFAULT)
        `uvm_field_int(tx_ready, UVM_DEFAULT)
    `uvm_object_utils_end

endclass

class i2c_tx_seq extends uvm_sequence #(i2c_seq_item);
    `uvm_object_utils(i2c_tx_seq)

    int num_txns = 50;

    function new(string name = "i2c_tx_seq");
        super.new(name);
    endfunction

    virtual task body();
        i2c_seq_item txn;

        `uvm_info(
            get_type_name(),
            $sformatf(
                " == i2c 전송 시퀀스 시작 (트랜젝션 %0d개) ==",
                num_txns), UVM_MEDIUM)

        for (int i = 0; i < num_txns; i++) begin
            txn = i2c_seq_item::type_id::create($sformatf("tx_txn_%0d", i));

            start_item(txn);

            if (!txn.randomize() with {
                    I2C_start == 1'b0;
                    I2C_stop == 1'b1;
                    
                    tx_data dist {
                        8'h00 := 2,        
                        8'hFF := 2,        
                        8'h55 := 2,        
                        8'hAA := 2,        
                        [8'h01:8'hFE] :/ 2 
                    };
                }) begin
                `uvm_error(get_type_name(), "트랜잭션 랜덤화 실패!")
            end

            finish_item(txn);

            `uvm_info(get_type_name(), $sformatf(
                      "[I2C 쓰기 %0d] tx_data=0x%02h, start=%0b, stop=%0b",
                      i,
                      txn.tx_data,
                      txn.I2C_start,
                      txn.I2C_stop
                      ), UVM_MEDIUM)
            #100000;
        end
        `uvm_info(get_type_name(),
                  "=== I2C 반복 전송 시퀀스 완료 ===", UVM_MEDIUM)
    endtask
endclass

class i2c_driver extends uvm_driver #(i2c_seq_item);
    `uvm_component_utils(i2c_driver)

    virtual I2C_if vif;
    i2c_seq_item req;
    int num_sent = 0;

    uvm_analysis_port #(i2c_seq_item) drv_ap;

    function new(string name = "I2C_DRV", uvm_component parent);
        super.new(name, parent);
        drv_ap = new("drv_ap", this);  
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual I2C_if)::get(this, "", "I2C_if", vif)) begin
            `uvm_fatal(get_type_name(), "Virtual interface get failed")
        end
    endfunction

    virtual task run_phase(uvm_phase phase);
        vif.drv_cb.I2C_En    <= 0;
        vif.drv_cb.I2C_start <= 0;
        vif.drv_cb.I2C_stop  <= 0;
        vif.drv_cb.tx_data   <= 0;

        `uvm_info(get_type_name(), "===I2C Driver RUN Phase===", UVM_LOW)

        forever begin
            seq_item_port.get_next_item(req);
            drive_transfer(req);
            seq_item_port.item_done();
        end
    endtask

    virtual task drive_transfer(i2c_seq_item item);
        wait (vif.drv_cb.tx_ready == 1'b1);

        @(vif.drv_cb);
        vif.drv_cb.I2C_En    <= item.I2C_En;
        vif.drv_cb.I2C_start <= item.I2C_start;
        vif.drv_cb.I2C_stop  <= item.I2C_stop;
        vif.drv_cb.tx_data   <= item.tx_data;

        num_sent++;

        drv_ap.write(item);

        `uvm_info(
            get_type_name(),
            $sformatf(
                "[드라이버 전송] tx_data = 0x%02h (총 전송 횟수 : %0d)",
                item.tx_data, num_sent), UVM_MEDIUM)

        @(vif.drv_cb iff vif.drv_cb.tx_ready == 1'b0);
        vif.drv_cb.I2C_En <= 0;
    endtask
endclass

class i2c_monitor extends uvm_monitor;
    `uvm_component_utils(i2c_monitor)

    virtual I2C_if vif;
    uvm_analysis_port #(i2c_seq_item) mon_ap;

    function new(string name = "I2C_MON", uvm_component parent);
        super.new(name, parent);
        mon_ap = new("mon_ap", this);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual I2C_if)::get(this, "", "I2C_if", vif)) begin
            `uvm_fatal(get_type_name(), "Virtual interface get failed")
        end
    endfunction

    virtual task run_phase(uvm_phase phase);
        i2c_seq_item item;
        logic [7:0] cap_data;

        `uvm_info(get_type_name(), "=== I2C Monitor Run Phase 시작 ===",
                  UVM_LOW)

        forever begin
            wait (vif.SCL === 1'b1 && vif.SDA === 1'b0);

            for (int i = 7; i >= 0; i--) begin
                @(posedge vif.SCL);
                cap_data[i] = vif.SDA;
            end

            @(posedge vif.SCL);  // ACK
            wait (vif.SCL === 1'b1 && vif.SDA === 1'b1);  // STOP

            item = i2c_seq_item::type_id::create("item");
            item.tx_data = cap_data;

            `uvm_info(
                get_type_name(), $sformatf(
                "[모니터 캡처] SDA 선로 데이터 = 0x%02h", item.tx_data
                ), UVM_MEDIUM)
            mon_ap.write(item);
        end
    endtask
endclass

class i2c_agent extends uvm_agent;
    `uvm_component_utils(i2c_agent)

    uvm_sequencer #(i2c_seq_item) seqr;
    i2c_driver drv;
    i2c_monitor mon;

    uvm_analysis_port #(i2c_seq_item) agt_ap;  
    uvm_analysis_port #(i2c_seq_item) agt_drv_ap;  

    function new(string name = "I2C_AGENT", uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        seqr = uvm_sequencer#(i2c_seq_item)::type_id::create("seqr", this);
        drv = i2c_driver::type_id::create("drv", this);
        mon = i2c_monitor::type_id::create("mon", this);
        agt_ap = new("agt_ap", this);
        agt_drv_ap = new("agt_drv_ap", this);  
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        drv.seq_item_port.connect(seqr.seq_item_export);
        mon.mon_ap.connect(agt_ap);
        drv.drv_ap.connect(agt_drv_ap);  
    endfunction
endclass

class i2c_coverage extends uvm_subscriber #(i2c_seq_item);
    `uvm_component_utils(i2c_coverage)

    i2c_seq_item cov_item;

    covergroup i2c_cg;
        cp_tx_data: coverpoint cov_item.tx_data {
            bins all_zero = {8'h00}; 
            bins all_one = {8'hFF};  
            bins toggle_0 = {8'h55}; 
            bins toggle_1 = {8'hAA}; 

            bins normal_low = {[8'h01 : 8'h54]};
            bins normal_mid = {[8'h56 : 8'hA9]};
            bins normal_high = {[8'hAB : 8'hFE]};
        }
    endgroup

    function new(string name = "I2C_COV", uvm_component parent);
        super.new(name, parent);
        i2c_cg = new();
    endfunction

    virtual function void write(i2c_seq_item t);
        cov_item = t;
        i2c_cg.sample();
    endfunction
endclass

class i2c_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(i2c_scoreboard)

    uvm_analysis_imp_drv #(i2c_seq_item, i2c_scoreboard) drv_imp;

    uvm_analysis_imp_mon #(i2c_seq_item, i2c_scoreboard) mon_imp;

    bit [7:0] exp_queue[$];

    int match_count = 0;
    int error_count = 0;

    function new(string name = "I2C_SCB", uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        drv_imp = new("drv_imp", this);
        mon_imp = new("mon_imp", this);
    endfunction

    virtual function void write_drv(i2c_seq_item txn);
        exp_queue.push_back(txn.tx_data);
    endfunction

    virtual function void write_mon(i2c_seq_item txn);
        bit [7:0] actual_data = txn.tx_data;
        bit [7:0] expected_data;

        if (exp_queue.size() > 0) begin
            expected_data = exp_queue.pop_front();

            if (actual_data === expected_data) begin
                match_count++;
                `uvm_info("SCB_PASS",
                          $sformatf(
                              "일치! 기댓값:0x%02h == 실제값:0x%02h",
                              expected_data, actual_data), UVM_LOW)
            end else begin
                error_count++;
                `uvm_error("SCB_FAIL", $sformatf(
                           "불일치! 기댓값:0x%02h != 실제값:0x%02h",
                           expected_data,
                           actual_data
                           ))
            end
        end else begin
            `uvm_warning("SCB_WARN",
                         "기댓값 큐가 비어있는데 선로에서 데이터가 감지되었습니다!")
        end
    endfunction

    virtual function void report_phase(uvm_phase phase);
        `uvm_info(get_type_name(), $sformatf(
                  "=== 스코어보드 결과: 매치 %0d건, 에러 %0d건 ===",
                  match_count,
                  error_count
                  ), UVM_LOW)
    endfunction
endclass

class i2c_env extends uvm_env;
    `uvm_component_utils(i2c_env)

    i2c_agent      agt;
    i2c_scoreboard scb;
    i2c_coverage   cov;

    function new(string name = "I2C_ENV", uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        agt = i2c_agent::type_id::create("agt", this);
        scb = i2c_scoreboard::type_id::create("scb", this);
        cov = i2c_coverage::type_id::create("cov", this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        agt.agt_drv_ap.connect(
            scb.drv_imp);  
        agt.agt_ap.connect(
            scb.mon_imp); 
        agt.agt_ap.connect(cov.analysis_export); 
    endfunction
endclass

class i2c_test extends uvm_test;
    `uvm_component_utils(i2c_test)

    i2c_env env;
    i2c_tx_seq tx_seq;

    function new(string name = "i2c_test", uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = i2c_env::type_id::create("env", this);
    endfunction

    virtual task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        tx_seq = i2c_tx_seq::type_id::create("tx_seq");

        `uvm_info(get_type_name(), "=== UVM TEST START ===", UVM_LOW)
        tx_seq.start(env.agt.seqr);
        #500000;

        phase.drop_objection(this);
    endtask
endclass

module tb_I2C_MASTER;
    bit clk;
    bit reset;

    always #5 clk = ~clk;

    I2C_if vif (
        clk,
        reset
    );

    I2C_MASTER dut (
        .clk      (clk),
        .reset    (reset),
        .I2C_En   (vif.I2C_En),
        .I2C_start(vif.I2C_start),
        .I2C_stop (vif.I2C_stop),
        .tx_data  (vif.tx_data),
        .tx_done  (vif.tx_done),
        .tx_ready (vif.tx_ready),
        .rx_data  (vif.rx_data),
        .rx_done  (vif.rx_done),
        .SCL      (vif.SCL),
        .SDA      (vif.SDA)
    );

    pullup (vif.SDA);

    initial begin
        $fsdbDumpfile("i2c_wave.fsdb");
        $fsdbDumpvars(0, tb_I2C_MASTER);
    end

    initial begin
        uvm_config_db#(virtual I2C_if)::set(null, "*", "I2C_if", vif);
        run_test("i2c_test");
    end

    initial begin
        clk   = 0;
        reset = 1;
        #20;
        reset = 0;
    end
endmodule