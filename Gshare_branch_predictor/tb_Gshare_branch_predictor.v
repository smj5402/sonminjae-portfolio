`timescale 1ns/1ps
module tb_Gshare_branch_predictor;

    reg clk, rst_n;

    reg  predict_valid;
    reg  [6:0] predict_pc;
    wire predict_taken;
    wire [6:0] predict_history;

    reg  train_valid;
    reg  train_taken;
    reg  train_mispredicted;
    reg  [6:0] train_history;
    reg  [6:0] train_pc;

    reg [6:0] saved_predict_history;

    
    Gshare_branch_predictor dut (
        .clk                (clk),
        .rst_n              (rst_n),
        .predict_valid      (predict_valid),
        .predict_pc         (predict_pc),
        .predict_taken      (predict_taken),
        .predict_history    (predict_history),
        .train_valid        (train_valid),
        .train_taken        (train_taken),
        .train_mispredicted (train_mispredicted),
        .train_history      (train_history),
        .train_pc           (train_pc)
    );

    // clk gen
    always #5 clk = ~clk;

    task predict_phase(input [6:0] pc);
        begin
            @(negedge clk);
            predict_valid = 1;
            predict_pc = pc;
            saved_predict_history = predict_history;
            @(negedge clk);
            predict_valid = 0;
        end
    endtask

    task train_phase(input [6:0] pc, input taken, input mispredicted);
        begin
            @(negedge clk);
            train_valid = 1;
            train_pc = pc;
            train_taken = taken;
            train_mispredicted = mispredicted;
            train_history = saved_predict_history;
            @(negedge clk);
            train_valid = 0;
        end
    endtask

    initial begin
        $display("Initialize values [%t]", $time);
        clk=0;
        rst_n=1;
        predict_valid=0;
        predict_pc=7'b0;
        train_valid=0;
        train_taken=0;
        train_mispredicted=0;
        train_history=7'b0;
        train_pc=7'b0;
        #50;

        $display("Reset [%t]", $time);
        rst_n = 0;
        #10;
        rst_n = 1;

        $display("Start Simulation [%t]", $time);
        
        $display("1. Predict when pc=10, suppose prediction fails [%t]", $time);
        predict_phase(7'd10);
        train_phase(7'd10, 1'b1, 1'b1);

        
        $display("2. Train when pc=10, suppose prediction succeeds [%t]", $time);
        predict_phase(7'd10);
        train_phase(7'd10, 1'b0, 1'b0);

        $display("3. Predict when pc=20, suppose prediction succeeds [%t]", $time);
        predict_phase(7'd20);
        train_phase(7'd20, 1'b0, 1'b0);

        $display("4. Predict when pc=14, suppose prediction fails [%t]", $time);
        predict_phase(7'd14);
        train_phase(7'd14, 1'b0, 1'b1);

        #50;
        $display("Finish Simulation [%t]", $time);
        $finish;
    end
endmodule