`timescale 1ns/1ps
module Gshare_branch_predictor_generic (
    input clk, rst_n,
    // Prediction interface
    input [6:0] predict_pc,
    input predict_valid,
    output predict_taken,
    output [6:0] current_history, // GHR at the point right before prediction
    // Train interface
    input [6:0] train_pc,
    input train_valid,
    input train_taken
    //output [6:0] train_history
);

    // PHT (Pattern History Table)
    reg [1:0] PHT [0:127];

    // GHR (Global History Register)
    reg [6:0] GHR;

    integer i;
    always@(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            GHR <= 7'b0;
            for(i=0; i<128; i=i+1) begin
            PHT[i] <=2'b01; // Initialize to Weakly Not Taken
            end
        end else begin
            //GHR update logic
            if(train_valid) begin
                GHR <= {GHR[5:0], train_taken};
            end else if(predict_valid) begin
                GHR <= {GHR[5:0], predict_taken};
            end

            // PHT update logic
            if(train_valid) begin
                reg[6:0] train_index;
                train_index = train_pc ^ GHR;
                if(train_taken) begin
                    PHT[train_index] = (PHT[train_index] == 2'b11) ? 2'b11 : PHT[train_index] + 1'b1;
                end else begin
                    PHT[train_index] = (PHT[train_index] == 2'b00) ? 2'b00 : PHT[train_index] - 1'b1;
                end
            end
        end
    end

    wire[6:0] predict_index;
    assign predict_index = predict_pc ^ GHR;
    assign predict_taken = PHT[predict_index][1];
    assign current_history = GHR;

endmodule