class spi_rx_monitor extends uvm_monitor;
    `uvm_component_utils(spi_rx_monitor)

    virtual spi_if vif;

    uvm_analysis_port #(spi_seq_item) ap;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap = new("ap", this);
        if (!uvm_config_db #(virtual spi_if)::get(this, "", "vif", vif))
            `uvm_fatal("NO_VIF", "spi_rx_monitor: virtual spi_if not found in config_db")
    endfunction

    task run_phase(uvm_phase phase);
        spi_seq_item item;
        @(negedge vif.reset);

        // rd_en starts LOW (deassert)
        vif.rx_cb.rx_rd_en <= 1'b0;
        @(vif.rx_cb);

        forever begin
            @(vif.rx_cb);   // posedge clk + 1 ns

            if (!vif.rx_cb.rx_empty) begin
                item      = spi_seq_item::type_id::create("rx_mon_item");
                item.data = vif.rx_cb.rx_rd_data;

                vif.rx_cb.rx_rd_en <= 1'b1;
                @(vif.rx_cb);
                vif.rx_cb.rx_rd_en <= 1'b0;

                ap.write(item);
                `uvm_info("RX_MON",
                    $sformatf("Observed RX read:  data=0x%02h", item.data),
                    UVM_HIGH)
            end
        end
    endtask

endclass
