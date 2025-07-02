
`timescale 1ns/1ps
module Gshare_branch_predictor(
    input clk,
    input rst_n,

    input  predict_valid,
    input  [6:0] predict_pc,
    output predict_taken,
    output [6:0] predict_history,

    input train_valid,
    input train_taken,
    input train_mispredicted,
    input [6:0] train_history,
    input [6:0] train_pc
);

    reg [6:0] r_predict_history; // almost the same as GHR
    reg [1:0] PHT [0:127];

    integer i;
    always@(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            r_predict_history <= 7'b0;
            for(i=0; i<128; i=i+1) PHT[i] <= 2'b01;
        end else begin
            // GHR update
            if(train_valid && train_mispredicted) begin
                // Recovery logic on misprediction
                r_predict_history <= { train_history[5:0], train_taken};   													  
            end else if(predict_valid) begin
                // GHR update
                r_predict_history <= { predict_history[5:0], predict_taken}; 
            end

    		// PHT update
            if(train_valid) begin
                if(train_taken) begin
                    PHT[train_pc^train_history] <= (PHT[train_pc^train_history]==2'b11) ? 2'b11 : (PHT[train_pc^train_history]+1'b1);
                end else begin
                    PHT[train_pc^train_history] <= (PHT[train_pc^train_history]==2'b00) ? 2'b00 : (PHT[train_pc^train_history]-1'b1);
                end
            end
        end
    end
    
// 00 : Strong Not-Taken
// 01 : Weak   Not-Taken
// 10 : Weak   Taken
// 11 : Strong Taken    
// -> When PHT[i][1] ==0, Not taken  
//                   ==1, Taken 
    assign predict_taken = PHT[predict_pc^predict_history][1];
    assign predict_history  = r_predict_history;
endmodule