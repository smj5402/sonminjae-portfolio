`timescale 1ns / 1ps
`include "define.vh"
module data_mem (
    input               clk,
    // input               d_we,
    input        [ 2:0] funct3,
    input        [ 3:0] b_we,
    input        [ 6:0] daddr,
    input        [ 1:0] byte_sel,
    input        [31:0] dwdata,
    output logic [31:0] drdata
);

    // word addressing
    logic [31:0] data_ram[0:127];
    logic [31:0] raw_data;
    logic [31:0] shifted_data_load;
    logic [31:0] shifted_data_store;

    // store logic
    always_comb begin
        case (funct3)
            `SB: begin
                case (byte_sel)
                    2'b00: shifted_data_store = {24'b0, dwdata[7:0]};
                    2'b01: shifted_data_store = {16'b0, dwdata[7:0], 8'b0};
                    2'b10: shifted_data_store = {8'b0, dwdata[7:0], 16'b0};
                    2'b11: shifted_data_store = {dwdata[7:0], 24'b0};
                endcase
            end
            `SH:
            shifted_data_store = byte_sel[1] ? {dwdata[15:0], 16'b0} : {16'b0, dwdata[15:0]};
            `SW: shifted_data_store = dwdata;
            default: shifted_data_store = dwdata;
        endcase
    end

    always_ff @(posedge clk) begin
        if (b_we[0]) data_ram[daddr][7:0] <= shifted_data_store[7:0];
        if (b_we[1]) data_ram[daddr][15:8] <= shifted_data_store[15:8];
        if (b_we[2]) data_ram[daddr][23:16] <= shifted_data_store[23:16];
        if (b_we[3]) data_ram[daddr][31:24] <= shifted_data_store[31:24];
    end



    // load
    assign raw_data = data_ram[daddr];
    assign shifted_data_load = raw_data >> (byte_sel * 8);

    always_comb begin
        drdata = shifted_data_load;
        case (funct3)
            `LB: drdata = {{24{shifted_data_load[7]}}, shifted_data_load[7:0]};
            `LH:
            drdata = {{16{shifted_data_load[15]}}, shifted_data_load[15:0]};
            `LW: drdata = shifted_data_load;
            `LBU: drdata = {24'b0, shifted_data_load[7:0]};
            `LHU: drdata = {{16'b0}, shifted_data_load[15:0]};
            default: drdata = shifted_data_load;
        endcase
    end

endmodule
