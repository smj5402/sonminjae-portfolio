class spi_base_test extends uvm_test;
    `uvm_component_utils(spi_base_test)

    spi_env env;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = spi_env::type_id::create("env", this);
    endfunction


    protected task wait_drain(int unsigned num_bytes);
        int unsigned cycles = num_bytes * 200 + 500;
        repeat (cycles) @(posedge env.tx_agent.tx_monitor.vif.clk);
    endtask

endclass

//  256 times random test 
class spi_random_test extends spi_base_test;
    `uvm_component_utils(spi_random_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        spi_random_seq seq;
        phase.raise_objection(this);

        seq           = spi_random_seq::type_id::create("seq");
        seq.num_pkts  = 256;
        seq.start(env.tx_agent.sequencer);

        wait_drain(seq.num_pkts);
        phase.drop_objection(this);
    endtask

endclass

//  incremental from 0x00 to 0xFF 
class spi_incr_test extends spi_base_test;
    `uvm_component_utils(spi_incr_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        spi_incr_seq seq;
        phase.raise_objection(this);

        seq = spi_incr_seq::type_id::create("seq");
        seq.start(env.tx_agent.sequencer);

        wait_drain(256);
        phase.drop_objection(this);
    endtask

endclass

