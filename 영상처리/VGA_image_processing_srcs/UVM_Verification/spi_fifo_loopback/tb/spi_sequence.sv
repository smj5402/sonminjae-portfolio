//  base 
class spi_base_seq extends uvm_sequence #(spi_seq_item);
    `uvm_object_utils(spi_base_seq)

    function new(string name = "spi_base_seq");
        super.new(name);
    endfunction

    task send_item(spi_seq_item item);
        start_item(item);
        if (!item.randomize())
            `uvm_fatal("RAND", "Randomization failed")
        finish_item(item);
    endtask

endclass

//  random N bytes (data only, mode 0) 
class spi_random_seq extends spi_base_seq;
    `uvm_object_utils(spi_random_seq)

    int unsigned num_pkts = 10;

    function new(string name = "spi_random_seq");
        super.new(name);
    endfunction

    task body();
        spi_seq_item item;
        repeat (num_pkts) begin
            item = spi_seq_item::type_id::create("item");
            send_item(item);
            `uvm_info("SEQ", $sformatf("Queued: %s", item.convert2string()), UVM_HIGH)
        end
    endtask

endclass

//  incremental 0x00–0xFF 
class spi_incr_seq extends spi_base_seq;
    `uvm_object_utils(spi_incr_seq)

    function new(string name = "spi_incr_seq");
        super.new(name);
    endfunction

    task body();
        spi_seq_item item;
        for (int i = 0; i < 256; i++) begin
            item = spi_seq_item::type_id::create("item");
            start_item(item);
            item.data = i[7:0];
            finish_item(item);
        end
    endtask

endclass

