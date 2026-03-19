
class spi_seq_item extends uvm_sequence_item;
    `uvm_object_utils_begin(spi_seq_item)
        `uvm_field_int(data,     UVM_ALL_ON)
        `uvm_field_int(tx_full,  UVM_ALL_ON)
        `uvm_field_int(tx_empty, UVM_ALL_ON)
    `uvm_object_utils_end

    rand logic [7:0] data;

    // FIFO state 
    logic tx_full;
    logic tx_empty;

    constraint boundary_c {
        data dist { 8'h00 := 20, 8'hFF := 20, [8'h01:8'hFE] :/ 60 };
    }

    function new(string name = "spi_seq_item");
        super.new(name);
        tx_full  = 1'b0;
        tx_empty = 1'b1;
    endfunction

    function string convert2string();
        return $sformatf("data=0x%02h", data);
    endfunction

endclass
