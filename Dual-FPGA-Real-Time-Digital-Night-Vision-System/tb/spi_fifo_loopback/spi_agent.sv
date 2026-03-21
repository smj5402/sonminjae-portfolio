class spi_agent extends uvm_agent;
    `uvm_component_utils(spi_agent)

    spi_sequencer  sequencer;
    spi_driver     driver;
    spi_tx_monitor tx_monitor;

    uvm_analysis_port #(spi_seq_item) ap;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap         = new("ap", this);
        tx_monitor = spi_tx_monitor::type_id::create("tx_monitor", this);

        if (get_is_active() == UVM_ACTIVE) begin
            sequencer = spi_sequencer::type_id::create("sequencer", this);
            driver    = spi_driver::type_id::create("driver", this);
        end
    endfunction

    function void connect_phase(uvm_phase phase);
        if (get_is_active() == UVM_ACTIVE)
            driver.seq_item_port.connect(sequencer.seq_item_export);

        tx_monitor.ap.connect(ap);
    endfunction

endclass
