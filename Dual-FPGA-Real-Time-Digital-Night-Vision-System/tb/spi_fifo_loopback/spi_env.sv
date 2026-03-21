class spi_env extends uvm_env;
    `uvm_component_utils(spi_env)

    spi_agent      tx_agent;    // active: drives test vectors into TX FIFO
    spi_rx_monitor rx_monitor;  // passive: drains RX FIFO and reports received bytes
    spi_scoreboard scoreboard;
    spi_coverage   coverage;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        tx_agent   = spi_agent     ::type_id::create("tx_agent",   this);
        rx_monitor = spi_rx_monitor::type_id::create("rx_monitor", this);
        scoreboard = spi_scoreboard::type_id::create("scoreboard", this);
        coverage   = spi_coverage  ::type_id::create("coverage",   this);
    endfunction

    function void connect_phase(uvm_phase phase);
        // TX monitor -> scoreboard (expected side) + coverage
        tx_agent.ap.connect(scoreboard.tx_ap);
        tx_agent.ap.connect(coverage.tx_ap);

        // RX monitor -> scoreboard (actual side) + coverage
        rx_monitor.ap.connect(scoreboard.rx_ap);
        rx_monitor.ap.connect(coverage.rx_ap);
    endfunction

endclass
