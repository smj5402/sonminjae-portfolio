
package spi_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    `uvm_analysis_imp_decl(_tx)
    `uvm_analysis_imp_decl(_rx)

    `include "spi_seq_item.sv"
    `include "spi_sequencer.sv"
    `include "spi_sequence.sv"
    `include "spi_driver.sv"
    `include "spi_tx_monitor.sv"
    `include "spi_rx_monitor.sv"
    `include "spi_scoreboard.sv"
    `include "spi_coverage.sv"
    `include "spi_agent.sv"
    `include "spi_env.sv"
    `include "spi_test.sv"

endpackage
