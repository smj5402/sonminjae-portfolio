`timescale 1ns / 1ps
`include "uvm_macros.svh"
import uvm_pkg::*;


//////////////////////////////////////// Interface
interface sccb_if (
    input logic clk
);
    logic       reset;
    logic       scl;
    wire        sda;

    // signals for monitoring : assign 
    logic [7:0] tx_data;
    logic       tx_done;
    logic       tx_ready;
    logic       i2c_en;
    logic       i2c_stop;

    clocking mon_cb @(posedge clk);
        default input #1step;
        input scl, sda, tx_done, tx_ready, i2c_en, i2c_stop, tx_data;
    endclocking

    modport mon(clocking mon_cb, input reset, scl, sda);

    covergroup sccb_bus_cg @(posedge clk);
        // SCL 
        cp_scl: coverpoint scl {
            bins scl_high = {1'b1}; bins scl_low = {1'b0};
        }
        // SDA 
        cp_sda: coverpoint sda {
            bins sda_high = {1'b1}; bins sda_low = {1'b0};
        }
        // I2C 마스터 활성화 
        cp_i2c_en: coverpoint i2c_en {
            bins active = {1'b1}; bins inactive = {1'b0};
        }
        // tx_done 
        cp_tx_done: coverpoint tx_done {
            bins byte_sent = {1'b1};
        }
        // STOP 
        cp_i2c_stop: coverpoint i2c_stop {
            bins stop_req = {1'b1};
        }
        // SCL × SDA 
        cx_scl_sda: cross cp_scl, cp_sda;
    endgroup

    sccb_bus_cg bus_cov_inst = new();
endinterface

/////////////////////////////////// sccb_item  –  I2C 쓰기 트랜잭션 1건 (3바이트)
class sccb_item extends uvm_sequence_item;
    bit [7:0] slave_addr;
    bit [7:0] reg_addr;
    bit [7:0] data;

    `uvm_object_utils_begin(sccb_item)
        `uvm_field_int(slave_addr, UVM_ALL_ON)
        `uvm_field_int(reg_addr, UVM_ALL_ON)
        `uvm_field_int(data, UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "sccb_item");
        super.new(name);
    endfunction

    function string convert2string();
        return $sformatf("slave=0x%02X  reg=0x%02X  data=0x%02X", slave_addr,
                         reg_addr, data);
    endfunction
endclass

// Monitor  –  SCL/SDA 버스 직접 디코딩
class sccb_monitor extends uvm_monitor;
    `uvm_component_utils(sccb_monitor)

    virtual sccb_if vif;
    uvm_analysis_port #(sccb_item) ap;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap = new("ap", this);
        if (!uvm_config_db#(virtual sccb_if)::get(this, "", "vif", vif))
            `uvm_fatal(get_type_name(), "Virtual interface not found")
    endfunction

    // START 조건: SCL=1 유지 중 SDA 1→0
    task automatic detect_start();
        bit prev_scl, prev_sda;
        @(vif.mon_cb);
        prev_scl = vif.mon_cb.scl;
        prev_sda = vif.mon_cb.sda;
        forever begin
            @(vif.mon_cb);
            if (prev_scl === 1'b1 && vif.mon_cb.scl === 1'b1 &&
                prev_sda === 1'b1 && vif.mon_cb.sda === 1'b0)
                return;
            prev_scl = vif.mon_cb.scl;
            prev_sda = vif.mon_cb.sda;
        end
    endtask

    // 1바이트 수신 (MSB first, SCL 상승엣지에서 SDA sampling)
    task automatic receive_byte(output bit [7:0] data_out);
        bit prev_scl;
        int bit_count;
        bit_count = 0;
        @(vif.mon_cb);
        prev_scl = vif.mon_cb.scl;
        while (bit_count < 8) begin
            @(vif.mon_cb);
            if (prev_scl === 1'b0 && vif.mon_cb.scl === 1'b1) begin
                data_out[7-bit_count] = vif.mon_cb.sda;
                bit_count++;
            end
            prev_scl = vif.mon_cb.scl;
        end
    endtask

    // ACK/NACK 1비트 skip
    task automatic skip_ack();
        bit prev_scl;
        @(vif.mon_cb);
        prev_scl = vif.mon_cb.scl;
        forever begin
            @(vif.mon_cb);
            if (prev_scl === 1'b0 && vif.mon_cb.scl === 1'b1) break;
            prev_scl = vif.mon_cb.scl;
        end
        forever begin
            @(vif.mon_cb);
            if (prev_scl === 1'b1 && vif.mon_cb.scl === 1'b0) break;
            prev_scl = vif.mon_cb.scl;
        end
    endtask

    task run_phase(uvm_phase phase);
        sccb_item item;
        bit [7:0] b[3];

        @(negedge vif.reset);

        forever begin
            detect_start();

            for (int i = 0; i < 3; i++) begin
                receive_byte(b[i]);
                skip_ack();
            end

            item            = sccb_item::type_id::create("mon_item");
            item.slave_addr = b[0];
            item.reg_addr   = b[1];
            item.data       = b[2];

            `uvm_info(get_type_name(), $sformatf(
                      "Captured SCCB TX: %s", item.convert2string()),
                      UVM_MEDIUM)
            ap.write(item);
        end
    endtask
endclass

class sccb_coverage extends uvm_subscriber #(sccb_item);
    `uvm_component_utils(sccb_coverage)

    sccb_item    item;
    int unsigned tx_count = 0;

    covergroup sccb_trans_cg;

        // slave address: OV7670은 항상 0x42
        cp_slave_addr: coverpoint item.slave_addr {
            bins ov7670_write = {8'h42};
            // bins ov7670_read = {8'h43};  // 이 테스트에선 hit 안됨
            bins other = default;
        }

        // 레지스터 주소: OV7670 주요 그룹별 bins
        cp_reg_addr: coverpoint item.reg_addr {
            bins reset_com7 = {8'h12};  // COM7 (all registers 리셋)
            bins clkrc = {8'h11};  // CLKRC
            bins gain_awb = {[8'h00 : 8'h10]};  // Gain, AWB
            bins com_ctrl = {[8'h13 : 8'h1E]};  // COM3~COM14
            bins aec_agc = {[8'h1F : 8'h3F]};  // AEC/AGC
            bins format_ctrl = {[8'h40 : 8'h4E]};  // Format/Timing
            bins color_matrix = {[8'h4F : 8'h79]};  // Color Matrix
            bins gamma = {[8'h7A : 8'h9F]};  // Gamma Curve
            bins denoise_edge = {[8'hA0 : 8'hBF]};  // Denoise/Edge
            bins misc = default;
        }

        // 데이터 값 범위
        cp_data: coverpoint item.data {
            bins d_zero = {8'h00};
            // bins d_max = {8'hFF};
            bins d_low = {[8'h01 : 8'h3F]};
            bins d_mid_low = {[8'h40 : 8'h7F]};
            bins d_mid_high = {[8'h80 : 8'hBF]};
            bins d_high = {[8'hC0 : 8'hFE]};

            ignore_bins d_max = {8'hFF};
        }

        // reset(1개) → 메인 설정(76개) 순서 검증
        cp_tx_milestone: coverpoint tx_count {
            bins tx_first = {1};  // reset 트랜잭션
            bins tx_mid = {[2 : 76]};  // OV7670 레지스터 설정 중
            bins tx_last = {77};  // 마지막 트랜잭션
        }

        cx_reg_data: cross cp_reg_addr, cp_data {
            ignore_bins no_misc = binsof(cp_reg_addr.misc);

            // ── reset_com7(0x12): 0x80/0x00/0x11/0x14만 나옴 -> d_mid_low, d_high 없음
            ignore_bins reset_mid_low = binsof(cp_reg_addr.reset_com7) && binsof(cp_data.d_mid_low);
            ignore_bins reset_high    = binsof(cp_reg_addr.reset_com7) && binsof(cp_data.d_high);

            // ── clkrc(0x11): 0x01(d_low)만 나옴
            ignore_bins clkrc_zero     = binsof(cp_reg_addr.clkrc) && binsof(cp_data.d_zero);
            ignore_bins clkrc_mid_low  = binsof(cp_reg_addr.clkrc) && binsof(cp_data.d_mid_low);
            ignore_bins clkrc_mid_high = binsof(cp_reg_addr.clkrc) && binsof(cp_data.d_mid_high);
            ignore_bins clkrc_high     = binsof(cp_reg_addr.clkrc) && binsof(cp_data.d_high);

            // ── gain_awb(0x00~0x10): d_zero/d_low/d_mid_low만 나옴
            ignore_bins gain_mid_high = binsof(cp_reg_addr.gain_awb) && binsof(cp_data.d_mid_high);
            ignore_bins gain_high     = binsof(cp_reg_addr.gain_awb) && binsof(cp_data.d_high);

            // ── com_ctrl(0x13~0x1E): d_low/d_mid_low/d_high만 나옴
            ignore_bins com_zero     = binsof(cp_reg_addr.com_ctrl) && binsof(cp_data.d_zero);
            ignore_bins com_mid_high = binsof(cp_reg_addr.com_ctrl) && binsof(cp_data.d_mid_high);

            // ── aec_agc(0x1F~0x3F): d_zero/d_low/d_mid_high/d_high만 나옴
            ignore_bins aec_mid_low = binsof(cp_reg_addr.aec_agc) && binsof(cp_data.d_mid_low);

            // ── format_ctrl(0x40~0x4E): d_zero/d_high만 나옴 (40D0, 4200)
            ignore_bins fmt_low      = binsof(cp_reg_addr.format_ctrl) && binsof(cp_data.d_low);
            ignore_bins fmt_mid_low  = binsof(cp_reg_addr.format_ctrl) && binsof(cp_data.d_mid_low);
            ignore_bins fmt_mid_high = binsof(cp_reg_addr.format_ctrl) && binsof(cp_data.d_mid_high);

            // ── denoise_edge(0xA0~0xBF): d_low/d_mid_low/d_mid_high/d_high만 나옴
            ignore_bins denoise_zero = binsof(cp_reg_addr.denoise_edge) && binsof(cp_data.d_zero);

        }

    endgroup

    // ── I2C protocol 
    // slave_addr 이후 reg_addr -> data 순서로 수신됐는지 확인
    covergroup sccb_sequence_cg;

        cp_slave_addr_seq: coverpoint item.slave_addr {
            bins ov7670_write = {8'h42};
        }
        // reset 트랜잭션 확인 (reg_addr=0x12, data=0x80)
        cp_is_reset_tx: coverpoint (item.reg_addr == 8'h12 &&
                                    item.data     == 8'h80) {
            bins reset_tx = {1'b1}; bins normal_tx = {1'b0};
        }

        // slave_addr × reset  
        cx_slave_type: cross cp_slave_addr_seq, cp_is_reset_tx;

    endgroup

    function new(string name, uvm_component parent);
        super.new(name, parent);
        sccb_trans_cg    = new();
        sccb_sequence_cg = new();
    endfunction

    function void write(sccb_item t);
        item = t;
        tx_count++;
        sccb_trans_cg.sample();
        sccb_sequence_cg.sample();
    endfunction

    function void report_phase(uvm_phase phase);
        `uvm_info(get_type_name(), $sformatf(
                  "\n==============================\n  FUNCTIONAL COVERAGE REPORT\n  sccb_trans_cg    : %5.1f%%\n  sccb_sequence_cg : %5.1f%%\n  Total tx sampled : %0d\n==============================",
                  sccb_trans_cg.get_coverage(),
                  sccb_sequence_cg.get_coverage(),
                  tx_count
                  ), UVM_NONE)
    endfunction
endclass

////////////////////////////////////// Scoreboard
class sccb_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(sccb_scoreboard)

    uvm_analysis_imp #(sccb_item, sccb_scoreboard) analysis_imp;

    localparam int EXPECTED_TX = 77;  // 1(reset) + 76(OV7670 레지스터)

    logic [15:0] golden_mem [0:75];

    int tx_count   = 0;
    int pass_count = 0;
    int err_count  = 0;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        analysis_imp = new("analysis_imp", this);
        $readmemh("./rtl/OV7670.mem", golden_mem);
    endfunction

    function void write(sccb_item item);
        bit [7:0] exp_reg_addr, exp_reg_data;
        bit is_match;

        tx_count++;
        is_match = 1'b1;

        // slave_addr은 모든 트랜잭션에서 항상 확인
        if (item.slave_addr !== 8'h42) begin
            is_match = 1'b0;
            `uvm_error(get_type_name(), $sformatf(
                "[TX%0d] FAIL  slave_addr=0x%02X (expected 0x42)  PASS:%0d / FAIL:%0d",
                tx_count, item.slave_addr, pass_count, err_count))
        end else if (tx_count == 1) begin
            if (item.reg_addr !== 8'h12 || item.data !== 8'h80) begin
                is_match = 1'b0;
                `uvm_error(get_type_name(), $sformatf(
                    "[TX%0d] RESET FAIL  Got reg=0x%02X data=0x%02X, Exp reg=0x12 data=0x80",
                    tx_count, item.reg_addr, item.data))
            end
        end else begin
            // TX2~77: golden_mem[0]~golden_mem[75] 와 비교
            exp_reg_addr = golden_mem[tx_count-2][15:8];
            exp_reg_data = golden_mem[tx_count-2][7:0];
            if (item.reg_addr !== exp_reg_addr || item.data !== exp_reg_data) begin
                is_match = 1'b0;
                `uvm_error(get_type_name(), $sformatf(
                    "[TX%0d] FAIL  Got reg=0x%02X data=0x%02X, Exp reg=0x%02X data=0x%02X  (mem[%0d])  PASS:%0d / FAIL:%0d",
                    tx_count, item.reg_addr, item.data,
                    exp_reg_addr, exp_reg_data, tx_count-2,
                    pass_count, err_count))
            end
        end

        if (is_match) begin
            pass_count++;
            `uvm_info(get_type_name(), $sformatf(
                      "[TX%0d] PASS  %s  (PASS:%0d / FAIL:%0d)",
                      tx_count, item.convert2string(), pass_count, err_count
                      ), UVM_LOW)
        end else begin
            err_count++;
        end
    endfunction

    function void report_phase(uvm_phase phase);
        real pass_rate;
        pass_rate = (tx_count > 0) ? (pass_count * 100.0 / tx_count) : 0.0;

        `uvm_info(get_type_name(), $sformatf(
                  "\n========================================\n  SCOREBOARD REPORT\n  Total TX : %0d / %0d\n  PASS     : %0d\n  FAIL     : %0d\n  Pass Rate: %5.1f%%\n========================================",
                  tx_count,
                  EXPECTED_TX,
                  pass_count,
                  err_count,
                  pass_rate
                  ), UVM_NONE)

        if (tx_count != EXPECTED_TX)
            `uvm_error(get_type_name(), $sformatf(
                       "TX count mismatch: got %0d, expected %0d",
                       tx_count,
                       EXPECTED_TX
                       ))

        if (err_count == 0 && tx_count == EXPECTED_TX)
            `uvm_info(
                get_type_name(), $sformatf(
                "*** TEST PASSED ***  (%0d/%0d TX OK)", pass_count, EXPECTED_TX
                ), UVM_NONE)
        else
            `uvm_error(get_type_name(), $sformatf(
                       "*** TEST FAILED ***  (PASS:%0d  FAIL:%0d  MISSING:%0d)",
                       pass_count,
                       err_count,
                       EXPECTED_TX - tx_count
                       ))
    endfunction
endclass

//////////////////////////////// Agent
class sccb_agent extends uvm_agent;
    `uvm_component_utils(sccb_agent)

    sccb_monitor monitor;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        monitor = sccb_monitor::type_id::create("monitor", this);
    endfunction
endclass

////////////////////////////////////// Environment
class sccb_env extends uvm_env;
    `uvm_component_utils(sccb_env)

    sccb_agent      agent;
    sccb_scoreboard scoreboard;
    sccb_coverage   coverage; 

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        agent      = sccb_agent::type_id::create("agent", this);
        scoreboard = sccb_scoreboard::type_id::create("scoreboard", this);
        coverage   = sccb_coverage::type_id::create("coverage", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        agent.monitor.ap.connect(scoreboard.analysis_imp);
        agent.monitor.ap.connect(coverage.analysis_export);
    endfunction
endclass

///////////////////////// Test
class sccb_test extends uvm_test;
    `uvm_component_utils(sccb_test)

    sccb_env env;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = sccb_env::type_id::create("env", this);
    endfunction

    task run_phase(uvm_phase phase);
        //   100ms (IDLE wait) + 30ms (WAIT_30MS) + ~27ms (77 tx) ~= 157ms
        phase.raise_objection(this);
        #200_000_000;  // 200ms 
        phase.drop_objection(this);
    endtask
endclass

//////////////////////// Testbench Top
module tb_sccb;

    initial begin
        $fsdbDumpfile("build/wave.fsdb");
        $fsdbDumpvars(0, tb_sccb, "+all");
    end

    bit clk;
    sccb_if vif (clk);

    always #5 clk = ~clk;  // 100MHz

    pullup (vif.sda);

    SCCB_Register_set dut (
        .clk  (clk),
        .reset(vif.reset),
        .scl  (vif.scl),
        .sda  (vif.sda)
    );

    ////// NO driving  (Just Monitoring)
    assign vif.tx_data  = dut.tx_data;
    assign vif.tx_done  = dut.tx_done;
    assign vif.tx_ready = dut.tx_ready;
    assign vif.i2c_en   = dut.U_REGISTER_SET.i2c_en;
    assign vif.i2c_stop = dut.U_REGISTER_SET.I2C_stop;

    initial begin
        vif.reset = 1'b1;
        #20;
        vif.reset = 1'b0;
    end

    initial begin
        uvm_config_db#(virtual sccb_if)::set(null, "*", "vif", vif);
        run_test("sccb_test");
    end
endmodule


