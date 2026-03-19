
class spi_coverage extends uvm_component;
    `uvm_component_utils(spi_coverage)

    spi_seq_item curr_tx;
    spi_seq_item curr_rx;

    uvm_analysis_imp_tx #(spi_seq_item, spi_coverage) tx_ap;
    uvm_analysis_imp_rx #(spi_seq_item, spi_coverage) rx_ap;

    //  TX covergroup 
    covergroup spi_tx_cg;

        cp_data: coverpoint curr_tx.data {
            bins zero   = {8'h00};
            bins ff     = {8'hFF};
            bins low    = {[8'h01 : 8'h3F]};
            bins mid_lo = {[8'h40 : 8'h7F]};
            bins mid_hi = {[8'h80 : 8'hBF]};
            bins high   = {[8'hC0 : 8'hFE]};
        }

        // 'full' is impossible -> ignore_bins
        cp_fifo_state: coverpoint {curr_tx.tx_full, curr_tx.tx_empty} {
            bins empty                  = {2'b01};
            bins normal                 = {2'b00};
            ignore_bins full_impossible = {2'b10};
        }

    endgroup

    //  RX covergroup 
    covergroup spi_rx_cg;

        cp_rx_data: coverpoint curr_rx.data {
            bins zero   = {8'h00};
            bins ff     = {8'hFF};
            bins low    = {[8'h01 : 8'h3F]};
            bins mid_lo = {[8'h40 : 8'h7F]};
            bins mid_hi = {[8'h80 : 8'hBF]};
            bins high   = {[8'hC0 : 8'hFE]};
        }
    endgroup

    function new(string name, uvm_component parent);
        super.new(name, parent);
        spi_tx_cg = new();
        spi_rx_cg = new();
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        tx_ap = new("tx_ap", this);
        rx_ap = new("rx_ap", this);
    endfunction

    function void write_tx(spi_seq_item t);
        curr_tx = t;
        spi_tx_cg.sample();
        if (t.tx_full)
            `uvm_error("COV", $sformatf("Write attempted with TX FIFO full! data=0x%02h", t.data))
    endfunction

    function void write_rx(spi_seq_item t);
        curr_rx = t;
        spi_rx_cg.sample();
    endfunction

    function void report_phase(uvm_phase phase);
        `uvm_info("COV",
            $sformatf("TX Coverage = %.2f %%  |  RX Coverage = %.2f %%",
                      spi_tx_cg.get_coverage(), spi_rx_cg.get_coverage()),
            UVM_NONE)
    endfunction

endclass
