class spi_driver extends uvm_driver #(spi_seq_item);
    `uvm_component_utils(spi_driver)

    virtual spi_if vif;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db #(virtual spi_if)::get(this, "", "vif", vif))
            `uvm_fatal("NO_VIF", "spi_driver: virtual spi_if not found in config_db")
    endfunction

    task run_phase(uvm_phase phase);
        spi_seq_item item;

        //  initialize outputs 
        vif.tx_cb.tx_wr_en   <= 1'b0;
        vif.tx_cb.tx_wr_data <= 8'h00;

        //  wait for reset LOW 
        @(negedge vif.reset);
        repeat (5) @(vif.tx_cb);

        forever begin
            seq_item_port.get_next_item(item);
            drive_item(item);
            seq_item_port.item_done();
        end
    endtask

    task drive_item(spi_seq_item item);
        bit ready;
        ready = 0;
        while (!ready) begin
            while (vif.tx_cb.tx_full) begin
                `uvm_info("DRV", "TX FIFO full - waiting...", UVM_HIGH)
                @(vif.tx_cb);
            end
            @(vif.tx_cb);  // CDC settling cycle
            ready = !vif.tx_cb.tx_full;
        end

        // Write one byte  (clk_25 domain)
        vif.tx_cb.tx_wr_en   <= 1'b1;
        vif.tx_cb.tx_wr_data <= item.data;
        @(vif.tx_cb);
        vif.tx_cb.tx_wr_en   <= 1'b0;

        `uvm_info("DRV", $sformatf("Drove %s", item.convert2string()), UVM_MEDIUM)
    endtask

endclass
