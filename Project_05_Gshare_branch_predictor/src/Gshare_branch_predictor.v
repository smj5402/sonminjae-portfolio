// Gshare Branch Predictor
// This module predicts branch direction using Global History Register(GHR) and 2-bit saturating counter
// Indexing Pattern History Table(PHT) using a simple hash PC using GHR
// If prediction occurs (mispredicted), GHR is restored
`timescale 1ns/1ps
module Gshare_branch_predictor(
    input clk,
    input rst_n,
    // Prediction interface
    input  predict_valid,
    input  [6:0] predict_pc,
    output predict_taken,
    output [6:0] predict_history,
    // Training interface
    input train_valid,
    input train_taken,
    input train_mispredicted,
    input [6:0] train_history,
    input [6:0] train_pc
);

    // Global History Register
    reg [6:0] GHR;

    // Pattern History Table with 2-bit saturating counter
    reg [1:0] PHT [0:127];

    integer i;

    // Wires for PHT indexing
    wire [6:0] predict_index;
    wire [6:0] train_index;
    assign predict_index = predict_pc ^ predict_history;
    assign train_index =  train_pc ^  train_history;

    always@(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            GHR <= 7'b0;
            for(i=0; i<128; i=i+1) PHT[i] <= 2'b01;
        end else begin
            // GHR update logic
            if(train_valid && train_mispredicted) begin
                // Restore GHR in misprediction
                GHR <= { train_history[5:0], train_taken};   													  
            end else if(predict_valid) begin
                // GHR update with latest prediction
                GHR <= { predict_history[5:0], predict_taken}; 
            end // else
            // GHR <= GHR;

    		// PHT update logic
            if(train_valid) begin
                if(train_taken) begin
                    PHT[train_index] <= (PHT[train_index]==2'b11) ? 2'b11 : (PHT[train_index]+1'b1);
                end else begin
                    PHT[train_index] <= (PHT[train_index]==2'b00) ? 2'b00 : (PHT[train_index]-1'b1);
                end
            end
        end
    end

// PHT 2-bit saturating counter states
// 00 : Strong Not-Taken
// 01 : Weak   Not-Taken
// 10 : Weak   Taken
// 11 : Strong Taken    
assign predict_taken = PHT[predict_index][1]; // MSB for prediction
assign predict_history  = GHR;
endmodule