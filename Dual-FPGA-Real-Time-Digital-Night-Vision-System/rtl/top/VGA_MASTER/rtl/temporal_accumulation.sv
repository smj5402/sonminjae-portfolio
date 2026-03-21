`timescale 1ns / 1ps


module temporal_accumulation (
    input  logic       pclk,
    input  logic       reset,
    input  logic       valid_in,
    input  logic       vsync_edge,
    input  logic [7:0] i_gray,
    output logic       valid_out,
    output logic       vsync_out,
    output logic [7:0] o_accumulated
);
    localparam TOTAL_PIX = 76_800;

    logic [16:0] addr = TOTAL_PIX - 1;

    (* ram_style = "block" *)logic [ 7:0] frame_buffer         [0:TOTAL_PIX -1];
    logic [ 7:0] old_avg;


    logic        valid_q;
    logic        vsync_q;
    logic [16:0] addr_q;
    logic [ 7:0] i_gray_q;


    //adder logic
    always_ff @(posedge pclk) begin
        if (reset || vsync_edge) begin
            addr <= 0;
        end else if (valid_in) begin
            if (addr == (TOTAL_PIX - 1)) addr <= 0;
            else addr <= addr + 1;
        end
    end

    //frame_buffer 
    //use 1_clk

    always_ff @(posedge pclk) begin
        if (reset) begin
            old_avg <= 0;
        end else begin
            old_avg <= frame_buffer[addr];
        end
    end

    // weight calculate logic (ALpha = 0.125 = 1/8, opencv 0.1과 비슷)
    //  NEW_AVG = OLD_AVG + Alpha * (Current - old)

    logic [7:0] new_avg;

    always_comb begin
        new_avg = old_avg - (old_avg >> 3) + (i_gray_q >> 3);
    end



    //write new AVG and out Data
    always_ff @(posedge pclk) begin
        if (valid_q) begin
            frame_buffer[addr_q] <= new_avg;
            o_accumulated <= new_avg;
        end
    end


    //Sync signals

    always_ff @(posedge pclk) begin
        if (reset) begin
            valid_q   <= 0;
            valid_out <= 0;
            vsync_out <= 0;
        end else begin
            valid_q   <= valid_in;
            vsync_q   <= vsync_edge;
            addr_q    <= addr;
            i_gray_q  <= i_gray;

            valid_out <= valid_q;
            vsync_out <= vsync_q;
        end
    end


endmodule
