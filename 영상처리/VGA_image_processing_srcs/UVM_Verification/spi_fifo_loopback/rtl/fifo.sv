`timescale 1ns / 1ps
module fifo #(
    parameter DATA_WIDTH = 8,
    MEM_SIZE = 8,
    ADDR_WIDTH = $clog2(MEM_SIZE)
) (
    input clk,
    input reset,
    input wr,
    input rd,
    input [DATA_WIDTH-1:0] wdata,
    output [DATA_WIDTH-1:0] rdata,
    output full,
    output empty
);
    wire [ADDR_WIDTH-1:0] w_wptr, w_rptr;
    register_file #(
        .DATA_WIDTH(DATA_WIDTH),
        .MEM_SIZE  (MEM_SIZE),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) U_REG_FILE (
        .clk  (clk),
        .waddr(w_wptr),
        .wdata(wdata),
        .raddr(w_rptr),
        .wr   (!full && wr),   // if( !full && wr)
        //.rd   (!empty && rd),   // necessary in sequential output
        .rdata(rdata)
    );

    fifo_control_unit #(
        .MEM_SIZE  (MEM_SIZE),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) U_FIFO_CU (
        .clk  (clk),
        .reset(reset),
        .wr   (wr),
        .rd   (rd),
        .w_ptr(w_wptr),
        .r_ptr(w_rptr),
        .full (full),
        .empty(empty)
    );

endmodule


// 4-bit memory
// otuput combinational logic 
module register_file #(
    parameter DATA_WIDTH = 8,
    MEM_SIZE = 4,
    ADDR_WIDTH = $clog2(MEM_SIZE)
) (
    input                         clk,
    input        [ADDR_WIDTH-1:0] waddr,
    input        [DATA_WIDTH-1:0] wdata,
    input        [ADDR_WIDTH-1:0] raddr,
    input                         wr,
    input                         rd,
    output logic [DATA_WIDTH-1:0] rdata
);
    // data 8bit, size 4 byte
    logic [7:0] register_file[0:(1<<ADDR_WIDTH)-1];

    always_ff @(posedge clk) begin
        // write, push
        if (wr) begin
            register_file[waddr] <= wdata;
        end
    end

    // read,  pop combinational logic
    assign rdata = register_file[raddr];
endmodule



// // 8-bit memory
// // otuput sequential logic
// module register_file #(
//     parameter DATA_WIDTH = 8,
//     MEM_SIZE = 4,
//     ADDR_WIDTH = $clog2(MEM_SIZE)
// ) (
//     input                         clk,
//     input        [ADDR_WIDTH-1:0] waddr,
//     input        [DATA_WIDTH-1:0] wdata,
//     input        [ADDR_WIDTH-1:0] raddr,
//     input                         wr,
//     input                         rd,
//     output logic [DATA_WIDTH-1:0] rdata
// );
//     // data 8bit, size 4 byte
//     logic [DATA_WIDTH-1:0] register_file[0:(1<<ADDR_WIDTH)-1];

//     always_ff @(posedge clk) begin
//         // write, push
//         if (wr) begin
//             register_file[waddr] <= wdata;
//         end else if (rd) begin
//             // read, pop
//             rdata <= register_file[raddr];
//         end
//     end

// endmodule



module fifo_control_unit #(
    parameter MEM_SIZE = 8,
    ADDR_WIDTH = $clog2(MEM_SIZE)
) (
    input                   clk,
    input                   reset,
    input                   wr,
    input                   rd,
    output [ADDR_WIDTH-1:0] w_ptr,
    output [ADDR_WIDTH-1:0] r_ptr,
    output                  full,
    output                  empty
);

    logic c_full, n_full, c_empty, n_empty;
    logic [ADDR_WIDTH-1:0] c_wptr, n_wptr, c_rptr, n_rptr;

    assign full  = c_full;
    assign empty = c_empty;
    assign w_ptr = c_wptr;
    assign r_ptr = c_rptr;

    // state register logic
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            c_full  <= 'b0;
            c_empty <= 'b1;
            c_wptr  <= 'b0;
            c_rptr  <= 'b0;
        end else begin
            c_full  <= n_full;
            c_empty <= n_empty;
            c_wptr  <= n_wptr;
            c_rptr  <= n_rptr;
        end
    end

    // next state logic
    always_comb begin
        // init
        n_full  = c_full;
        n_empty = c_empty;
        n_wptr  = c_wptr;
        n_rptr  = c_rptr;
        case ({
            wr, rd
        })
            // 2'b00: begin
            //     // IDLE
            // end
            2'b01: begin
                // POP
                n_full = 1'b0;
                if (!empty) begin
                    n_rptr = c_rptr + 1;

                    if (c_wptr == n_rptr) begin
                        n_empty = 1'b1;
                    end
                end
            end
            2'b10: begin
                // PUSH
                n_empty = 1'b0;
                if (!c_full) begin
                    n_wptr = c_wptr + 1;

                    if (c_rptr == n_wptr) begin
                        n_full = 1'b1;
                    end
                end
            end
            2'b11: begin
                // PUSH, POP
                if (c_empty == 1) begin
                    // only push
                    n_empty = 1'b0;
                    n_wptr  = c_wptr + 1;
                end else if (c_full == 1) begin
                    n_full = 1'b0;
                    n_rptr = c_rptr + 1;
                end else begin
                    // write, read ptr increase
                    n_wptr = c_wptr + 1;
                    n_rptr = c_rptr + 1;
                end
            end
            default: ;
        endcase


    end


endmodule

