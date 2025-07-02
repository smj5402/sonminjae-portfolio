`timescale 1ns/1ps
module tb_Serial_Receiver_Parity();
  
  reg clk,rst;
  reg i_data;
  wire [7:0] out_byte;
  wire done;
  
  Serial_Receiver_Parity DUT (
    .clk		(clk),
    .rst		(rst),
    .i_data		(i_data),
    .out_byte		(out_byte),
    .done		(done)
  );
  
  //clk gen
  always #5 clk=~clk; // period 10ns
  
  initial begin
    $display("initialize values [%t]", $time);
    clk=0;
    rst=0;
    i_data=1;
    
    #10;
    
    $display("Reset [%t]", $time);
    rst=1;
    #10;
    
    rst=0;
    #10;
    
    $display("Start Simulation [%t]", $time);
    
    // Test 1 : 8h0101_0101 -> parity bit has to be 1
    i_data=1; // IDLE
    #50;
    
    
    
    //Start bit 0
    i_data=0;
    #10;
    
    // send 8'h0101_0101 (8'h55)
    $display("Send bit 0 [%t]", $time); i_data=1; #10;
    $display("Send bit 1 [%t]", $time); i_data=0; #10;
    $display("Send bit 2 [%t]", $time); i_data=1; #10;
    $display("Send bit 3 [%t]", $time); i_data=0; #10;
    $display("Send bit 4 [%t]", $time); i_data=1; #10;
    $display("Send bit 5 [%t]", $time); i_data=0; #10;
    $display("Send bit 6 [%t]", $time); i_data=1; #10;
    $display("Send bit 7 [%t]", $time); i_data=0; #10;

    //Parity bit 1
    $display("Send parity bit [%t]", $time); i_data=1; #10;
    
    //Stop bit 1
    $display("Send Stop bit [%t]", $time); i_data=1;
    
    
    #10;
    
    $display("Received byte = %h, done = %b [%t]", out_byte, done, $time);
    
    if (out_byte == 8'h55 && done == 1'b1) begin
      $display("Test 1 : PASSED (data 0x55, Odd Parity OK)");
    end else begin
          $display("Test 1: FAILED");
    end
    
    
    
    
    
    // Test 2 : 8'h1010_1010 -> parity bit has to be 1
    i_data=1; // IDLE
    #50;
    
    
    
    //Start bit 0
    i_data=0;
    #10;
    
    // send 8'h1010_1010 (8'hAA)
    $display("Send bit 0 [%t]", $time); i_data=0; #10;
    $display("Send bit 1 [%t]", $time); i_data=1; #10;
    $display("Send bit 2 [%t]", $time); i_data=0; #10;
    $display("Send bit 3 [%t]", $time); i_data=1; #10;
    $display("Send bit 4 [%t]", $time); i_data=0; #10;
    $display("Send bit 5 [%t]", $time); i_data=1; #10;
    $display("Send bit 6 [%t]", $time); i_data=0; #10;
    $display("Send bit 7 [%t]", $time); i_data=1; #10;

    //Parity bit 1
    $display("Send parity bit [%t]", $time); i_data=1; #10;
    
    //Stop bit 1
    $display("Send Stop bit [%t]", $time); i_data=1;
    
    
    #10;
    
    $display("Received byte = %h, done = %b [%t]", out_byte, done, $time);
    
    if (out_byte == 8'hAA && done == 1'b1) begin
      $display("Test 2 : PASSED (data 0x55, Odd Parity OK)");
    end else begin
      $display("Test 2: FAILED");
    end
    
    
    
    // Test 3 : 8'h0000_0001 -> parity bit has to be 0
    i_data=1; // IDLE
    #50;
    
    
    
    //Start bit 0
    i_data=0;
    #10;
    
    // send 8'h0000_0001 (8'h01)
    $display("Send bit 0 [%t]", $time); i_data=1; #10;
    $display("Send bit 1 [%t]", $time); i_data=0; #10;
    $display("Send bit 2 [%t]", $time); i_data=0; #10;
    $display("Send bit 3 [%t]", $time); i_data=0; #10;
    $display("Send bit 4 [%t]", $time); i_data=0; #10;
    $display("Send bit 5 [%t]", $time); i_data=0; #10;
    $display("Send bit 6 [%t]", $time); i_data=0; #10;
    $display("Send bit 7 [%t]", $time); i_data=0; #10;

    //Parity bit 1 (expect Fail)
    $display("Send parity bit [%t]", $time); i_data=1; #10;
    
    //Stop bit 1
    $display("Send Stop bit [%t]", $time); i_data=1;
    
    
    #10;
    
    $display("Received byte = %h, done = %b [%t]", out_byte, done, $time);
    
    if (out_byte == 8'h01 && done == 1'b1) begin
      $display("Test 3 : PASSED (data 0x55, Odd Parity OK)");
    end else begin
      $display("Test 3: FAILED");
    end
    
    
    #100;
    
    $display("Finish Simulation [%t]", $time);
    $finish;
  end
endmodule