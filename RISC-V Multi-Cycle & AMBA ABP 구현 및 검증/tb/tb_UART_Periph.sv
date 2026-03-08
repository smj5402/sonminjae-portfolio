import uvm_pkg::*;
`include "uvm_macros.svh"


interface APB_if (
    input bit PCLK,
    input bit PRESET
);
    logic [31:0] PADDR;
    logic        PWRITE;
    logic        PENABLE;
    logic [31:0] PWDATA;
    logic        PSEL;
    logic [31:0] PRDATA;
    logic        PREADY;
endinterface

interface UART_if (
    input bit PCLK,
    input bit PRESET
);
    logic rx;
    logic tx;
endinterface


class apb_seq_item extends uvm_sequence_item;
    rand bit [31:0] PADDR;
    rand bit        PWRITE;
    rand bit [31:0] PWDATA;

    logic    [31:0] PRDATA;
    logic           PREADY;

    constraint c_addr_range {
        PADDR inside {[32'h10005000 : 32'h100050ff]};
    }

    function new(string name = "apb_seq_item");
        super.new(name);
    endfunction

    `uvm_object_utils_begin(apb_seq_item);
        `uvm_field_int(PADDR, UVM_DEFAULT)
        `uvm_field_int(PWRITE, UVM_DEFAULT)
        `uvm_field_int(PWDATA, UVM_DEFAULT)
    `uvm_object_utils_end

endclass

class uart_seq_item extends uvm_sequence_item;
    rand logic [7:0] rx_data;

    function new(string name = "uart_seq_item");
        super.new(name);
    endfunction

    `uvm_object_utils_begin(uart_seq_item)
        `uvm_field_int(rx_data, UVM_DEFAULT)
    `uvm_object_utils_end
endclass

class apb_write_seq extends uvm_sequence #(apb_seq_item);
    `uvm_object_utils(apb_write_seq)
    apb_seq_item apb_write_item;

    function new(string name = "apb_write_seq");
        super.new(name);
    endfunction

    task body();
        repeat (10) begin  // 10번 쓰기 
            apb_write_item = apb_seq_item::type_id::create("apb_write_item");
            start_item(apb_write_item);
            assert (apb_write_item.randomize() with {
                PWRITE == 1;
                PADDR == 32'h10005008;
            });  
            finish_item(apb_write_item);
        end
    endtask
endclass

class uart_tx_seq extends uvm_sequence #(uart_seq_item);
    `uvm_object_utils(uart_tx_seq)
    uart_seq_item uart_tx_item;

    function new(string name = "uart_tx_seq");
        super.new(name);
    endfunction

    task body();
        repeat (10) begin  // 10번 tx
            uart_tx_item = uart_seq_item::type_id::create("uart_tx_item");
            start_item(uart_tx_item);
            assert (uart_tx_item.randomize());
            finish_item(uart_tx_item);
        end
    endtask
endclass

class apb_read_seq extends uvm_sequence #(apb_seq_item);
    `uvm_object_utils(apb_read_seq)
    apb_seq_item apb_read_item;

    function new(string name = "apb_read_seq");
        super.new(name);
    endfunction

    task body();
        repeat (10) begin  // 10번 읽기
            apb_read_item = apb_seq_item::type_id::create("apb_read_item");
            start_item(apb_read_item);
            assert (apb_read_item.randomize() with {
                PWRITE == 0;
                PADDR == 32'h10005004;
            });  
            finish_item(apb_read_item);
            #1500000;
        end
    endtask
endclass

class apb_driver extends uvm_driver #(apb_seq_item);
    `uvm_component_utils(apb_driver)

    virtual APB_if a_if;
    apb_seq_item   apb_item;

    function new(string name = "APB_DRV", uvm_component c);
        super.new(name, c);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual APB_if)::get(this, "", "APB_if", a_if))
            `uvm_fatal("APB DRV", "Virtual interface get failed")
    endfunction

    task run_phase(uvm_phase phase);
        a_if.PSEL    <= 0;
        a_if.PENABLE <= 0;
        forever begin
            seq_item_port.get_next_item(apb_item);
            drive_transfer(apb_item);
            seq_item_port.item_done();
        end
    endtask

    task drive_transfer(apb_seq_item apb_item);
        @(posedge a_if.PCLK);
        a_if.PSEL   <= 1;
        a_if.PADDR  <= apb_item.PADDR;
        a_if.PWRITE <= apb_item.PWRITE;
        if (apb_item.PWRITE) a_if.PWDATA <= apb_item.PWDATA;

        @(posedge a_if.PCLK);
        a_if.PENABLE <= 1;  //ACCESS
        wait (a_if.PREADY == 1);
        if (!apb_item.PWRITE) begin
            apb_item.PRDATA <= a_if.PRDATA;
            apb_item.PREADY <= a_if.PREADY;
        end
        @(posedge a_if.PCLK);
        a_if.PSEL    <= 0;
        a_if.PENABLE <= 0;
    endtask
endclass  //

class uart_driver extends uvm_driver #(uart_seq_item);
    `uvm_component_utils(uart_driver)

    virtual UART_if u_if;
    uart_seq_item   uart_item;

    function new(string name = "UART_DRV", uvm_component c);
        super.new(name, c);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual UART_if)::get(this, "", "UART_if", u_if))
            `uvm_fatal("UART_DRV", "Virtual interface get failed")
    endfunction

    task run_phase(uvm_phase phase);
        u_if.rx <= 1;
        forever begin
            seq_item_port.get_next_item(uart_item);
            drive_serial(uart_item);
            seq_item_port.item_done();
        end
    endtask

    task drive_serial(uart_seq_item uart_item);
        u_if.rx <= 0;
        #(104160);

        for (int i = 0; i < 8; i++) begin
            u_if.rx <= uart_item.rx_data[i];
            #(104160);
        end

        u_if.rx <= 1;
        #(104160);
    endtask

endclass

class apb_monitor extends uvm_monitor;
    `uvm_component_utils(apb_monitor)

    virtual APB_if a_if;
    uvm_analysis_port #(apb_seq_item) mon_port;
    apb_seq_item apb_item;

    function new(string name = "MON_DRV", uvm_component c);
        super.new(name, c);
        mon_port = new("mon_port", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual APB_if)::get(this, "", "APB_if", a_if))
            `uvm_fatal("APB_MON", "Virtual interface get failed")
    endfunction

    task run_phase(uvm_phase phase);
        forever begin
            @(posedge a_if.PCLK);
            if (a_if.PSEL && a_if.PENABLE && a_if.PREADY) begin
                apb_item        = apb_seq_item::type_id::create("apb_item");
                apb_item.PADDR  = a_if.PADDR;
                apb_item.PWRITE = a_if.PWRITE;
                if (a_if.PWRITE) begin
                    apb_item.PWDATA = a_if.PWDATA;
                end else begin
                    apb_item.PRDATA = a_if.PRDATA;
                end
                mon_port.write(apb_item);
            end
        end
    endtask
endclass

class uart_monitor extends uvm_monitor;
    `uvm_component_utils(uart_monitor)

    virtual UART_if u_if;
    uvm_analysis_port #(uart_seq_item) tx_port;
    uvm_analysis_port #(uart_seq_item) rx_port;
    uart_seq_item uart_item;

    logic [7:0] captured_data;

    function new(string name = "UART_MON", uvm_component c);
        super.new(name, c);
        tx_port = new("tx_port", this);
        rx_port = new("rx_port", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual UART_if)::get(this, "", "UART_if", u_if))
            `uvm_fatal("UART_MON", "Virtual interface get failed")
    endfunction

    task run_phase(uvm_phase phase);
        wait (u_if.PRESET == 0);
        fork
            monitor_tx();
            monitor_rx();
        join_none
    endtask

    task monitor_tx();
        logic [7:0] data;
        forever begin
            @(negedge u_if.tx);
            #(104160 / 2);
            for (int i = 0; i < 8; i++) begin
                #(104160);
                data[i] = u_if.tx;
            end
            #(104160);

            uart_item = uart_seq_item::type_id::create("uart_item");
            uart_item.rx_data = data;
            tx_port.write(uart_item);
        end
    endtask

    task monitor_rx();

        logic [7:0] data;
        forever begin
            @(negedge u_if.rx);
            #(104160 / 2);
            for (int i = 0; i < 8; i++) begin
                #(104160);
                data[i] = u_if.rx;
            end
            #(104160);

            uart_item = uart_seq_item::type_id::create("uart_item");
            uart_item.rx_data = data;
            rx_port.write(uart_item);
        end
    endtask

endclass

class apb_agent extends uvm_agent;
    `uvm_component_utils(apb_agent)

    apb_driver drv;
    apb_monitor mon;
    uvm_sequencer #(apb_seq_item) seqr;

    uvm_analysis_port #(apb_seq_item) mon_port;

    function new(string name = "APB_AGENT", uvm_component c);
        super.new(name, c);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        drv = apb_driver::type_id::create("drv", this);
        mon = apb_monitor::type_id::create("mon", this);
        seqr = uvm_sequencer#(apb_seq_item)::type_id::create("seqr", this);
        mon_port = new("mon_port", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        drv.seq_item_port.connect(seqr.seq_item_export);
        mon.mon_port.connect(mon_port);
    endfunction
endclass

class uart_agent extends uvm_agent;
    `uvm_component_utils(uart_agent)

    uart_driver drv;
    uart_monitor mon;
    uvm_sequencer #(uart_seq_item) seqr;

    uvm_analysis_port #(uart_seq_item) tx_port;
    uvm_analysis_port #(uart_seq_item) rx_port;

    function new(string name = "UART_AGENT", uvm_component c);
        super.new(name, c);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        drv = uart_driver::type_id::create("drv", this);
        mon = uart_monitor::type_id::create("mon", this);
        seqr = uvm_sequencer#(uart_seq_item)::type_id::create("seqr", this);
        tx_port = new("tx_port", this);
        rx_port = new("rx_port", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        drv.seq_item_port.connect(seqr.seq_item_export);
        mon.tx_port.connect(this.tx_port);
        mon.rx_port.connect(this.rx_port);
    endfunction
endclass

class scoreboard extends uvm_scoreboard;
    `uvm_component_utils(scoreboard)

    uvm_tlm_analysis_fifo #(apb_seq_item) apb_fifo;
    uvm_tlm_analysis_fifo #(uart_seq_item) uart_tx_fifo;
    uvm_tlm_analysis_fifo #(uart_seq_item) uart_rx_fifo;
    apb_seq_item apb_seq;
    uart_seq_item uart_seq;

    function new(string name = "SCB", uvm_component c);
        super.new(name, c);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        apb_fifo = new("apb_fifo", this);
        uart_tx_fifo = new("uart_tx_fifo", this);
        uart_rx_fifo = new("uart_rx_fifo", this);
    endfunction

    task run_phase(uvm_phase phase);

        forever begin

            apb_fifo.get(apb_seq);
            if (apb_seq.PWRITE) begin
                uart_tx_fifo.get(uart_seq);
                if (apb_seq.PWDATA[7:0] == uart_seq.rx_data) begin
                    `uvm_info("SCB", $sformatf("WRITE PASS! Data match : 0x%0h",
                                               uart_seq.rx_data), UVM_LOW)
                end else begin
                    `uvm_error("SCB", $sformatf(
                               "WRITE FAIL! APB : 0x%0h UART : 0x%0h",
                               apb_seq.PWDATA[7:0],
                               uart_seq.rx_data
                               ))
                end
            end else begin
                uart_rx_fifo.get(uart_seq);
                if (apb_seq.PRDATA[7:0] == uart_seq.rx_data) begin
                    `uvm_info("SCB", $sformatf("RX PASS Data match : 0x%0h",
                                               apb_seq.PRDATA), UVM_LOW)

                end else begin
                    `uvm_error("SCB", $sformatf(
                               "RX FAIL APB Read:0x%0h != UART rx:0x%0h",
                               apb_seq.PRDATA[7:0],
                               uart_seq.rx_data
                               ))
                end
            end
        end
    endtask
endclass

class env extends uvm_env;
    `uvm_component_utils(env)

    apb_agent  a_agent;
    uart_agent u_agent;
    scoreboard scb;

    function new(string name = "ENV", uvm_component c);
        super.new(name, c);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        a_agent = apb_agent::type_id::create("APB_AGT", this);
        u_agent = uart_agent::type_id::create("UART_AGT", this);
        scb = scoreboard::type_id::create("SCB", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        a_agent.mon_port.connect(scb.apb_fifo.analysis_export);
        u_agent.tx_port.connect(scb.uart_tx_fifo.analysis_export);
        u_agent.rx_port.connect(scb.uart_rx_fifo.analysis_export);
    endfunction
endclass

class test extends uvm_test;
    `uvm_component_utils(test)
    env e;
    apb_write_seq a_wr_seq;
    apb_read_seq a_rd_seq;
    uart_tx_seq u_tx_seq;

    function new(string name = "test", uvm_component c);
        super.new(name, c);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        e = env::type_id::create("e", this);
    endfunction

    task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        a_wr_seq = apb_write_seq::type_id::create("a_wr_seq");
        a_rd_seq = apb_read_seq::type_id::create("a_rd_seq");
        u_tx_seq = uart_tx_seq::type_id::create("u_tx_seq");

        `uvm_info("test", "SCENARIO 1 : tx TEST", UVM_LOW)
        a_wr_seq.start(e.a_agent.seqr);
        #(104160 * 10 * 3 *10);  


        `uvm_info("test", "SCENARIO 2 : APB Write → UART tx", UVM_LOW)
        fork
            u_tx_seq.start(e.u_agent.seqr);
            begin
                #1500000;
                a_rd_seq.start(e.a_agent.seqr);
            end
        join


        #1000000;
        phase.drop_objection(this);
    endtask
endclass

module tb_UART ();

    bit PCLK;
    bit PRESET;

    always #5 PCLK = ~PCLK;

    APB_if a_if (
        .PCLK  (PCLK),
        .PRESET(PRESET)
    );

    UART_if u_if (
        .PCLK  (PCLK),
        .PRESET(PRESET)
    );

    UART_Periph dut (
        .PCLK   (PCLK),
        .PRESET (PRESET),
        .PADDR  (a_if.PADDR),
        .PWRITE (a_if.PWRITE),
        .PENABLE(a_if.PENABLE),
        .PWDATA (a_if.PWDATA),
        .PSEL   (a_if.PSEL),
        .PRDATA (a_if.PRDATA),
        .PREADY (a_if.PREADY),

        .rx(u_if.rx),
        .tx(u_if.tx)
    );

    initial begin
        $fsdbDumpfile("build/wave.fsdb");
        $fsdbDumpvars(0, tb_UART);
    end

    initial begin
        PCLK   = 0;
        PRESET = 1;
        fork
            begin
                #15;
                PRESET = 0;
            end
        join_none
        uvm_config_db#(virtual APB_if)::set(null, "*", "APB_if", a_if);
        uvm_config_db#(virtual UART_if)::set(null, "*", "UART_if", u_if);
        run_test("test");
    end

endmodule
