
class spi_tx_monitor extends uvm_monitor;
    `uvm_component_utils(spi_tx_monitor)

    virtual spi_if vif;

    uvm_analysis_port #(spi_seq_item) ap;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap = new("ap", this);
        if (!uvm_config_db #(virtual spi_if)::get(this, "", "vif", vif))
            `uvm_fatal("NO_VIF", "spi_tx_monitor: virtual spi_if not found in config_db")
    endfunction

    task run_phase(uvm_phase phase);
        spi_seq_item item;
        @(negedge vif.reset);

        forever begin
            @(vif.tx_mon_cb);
            // Capture only when wr_en=1 and fifo is not full
            if (vif.tx_mon_cb.tx_wr_en) begin
                item          = spi_seq_item::type_id::create("tx_mon_item");
                item.data     = vif.tx_mon_cb.tx_wr_data;
                item.tx_full  = vif.tx_mon_cb.tx_full;
                item.tx_empty = vif.tx_mon_cb.tx_empty;
                ap.write(item);
                `uvm_info("TX_MON",
                    $sformatf("Observed TX write: %s (full=%0b empty=%0b)",
                              item.convert2string(), item.tx_full, item.tx_empty),
                    UVM_HIGH)
            end
        end
    endtask

endclass
