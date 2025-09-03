// tb_Serial_Receiver_Parity
// Testbench for Serial Receiver and checking odd parity system
`timescale 1ns/1ps
module tb_Serial_Rx_Parity();
  
  reg clk, rst_n;
  reg i_data;
  wire [7:0] out_byte;
  wire done;
  reg [7:0] temp_out_byte;
  reg temp_done;
  
  Serial_Rx_Parity DUT (
    .clk		  (clk),
    .rst_n		(rst_n),
    .i_data		(i_data),
    .out_byte	(out_byte),
    .done		  (done)
  );

  //clk gen
  always #5 clk=~clk; // period 10ns
  
  initial begin
    $display("initialize values at %t ns", $time);
    clk=0;
    rst_n=1;
    i_data=1;
    temp_out_byte = 0;
    temp_done = 0;

    #10;
    
    $display("Reset at %t ns", $time);
    rst_n=0;
    #10;
    
    rst_n=1;
    #30;
    
    $display("Start Simulation at %t ns", $time);

    //====================================================
    // Reset Test : rst_n (Active low reset test)
    // Expect : out_byte = 8'h00, done = 0
    //====================================================
    $display("\nReset(Active-low reset) Test ");
    
    // Assert rst_n 
    rst_n <= 0;
    @(negedge clk);

    //Start bit 0
    i_data<=0; 
    @(posedge clk);
    
    // send 8'h0101_0101 (8'h0f) 
    // if rst_n works properly out_byte will still be 8'h00
    $display("Send bit 0 at %t ns", $time); i_data<=1; @(posedge clk);
    $display("Send bit 1 at %t ns", $time); i_data<=1; @(posedge clk);
    $display("Send bit 2 at %t ns", $time); i_data<=1; @(posedge clk);
    $display("Send bit 3 at %t ns", $time); i_data<=1; @(posedge clk);
    $display("Send bit 4 at %t ns", $time); i_data<=0; @(posedge clk);
    $display("Send bit 5 at %t ns", $time); i_data<=0; @(posedge clk);
    $display("Send bit 6 at %t ns", $time); i_data<=0; @(posedge clk);
    $display("Send bit 7 at %t ns", $time); i_data<=0; @(posedge clk);

    //Parity bit 1
    $display("Send parity bit at %t ns", $time); i_data<=1; @(posedge clk);
    //Stop bit 1
    $display("Send Stop bit at %t ns", $time); i_data<=1;
  
    @(posedge clk);
    temp_out_byte = out_byte;
    
    #1;
    if (temp_out_byte == 8'h00 && done == 0) begin
      $display("PASS(rst_n worked properly): out_byte=%b, done=%b", temp_out_byte, done);
    end else begin
          $display("FAIL(outputs didn't reset): out_byte=%b, done=%b", temp_out_byte, done);
    end
    

    // Deassert rst_n
    rst_n <= 1;

    repeat(3) @(posedge clk);
    
    //=============================================
    // Test 1 : 8h0101_0101 + parity bit  1 (PASS)
    // Expect : done = 1, out_byte = 0x55
    //=============================================
    $display();
    $display("\nTest 1 : 8'h55 + parity 1 (PASS)");
    i_data <=1; // IDLE
    @(negedge clk);
    
    
    //Start bit 0
    i_data<=0; 
    @(posedge clk);
    
    // send 8'h0101_0101 (8'h55)
    $display("Send bit 0 at %t ns", $time); i_data<=1; @(posedge clk);
    $display("Send bit 1 at %t ns", $time); i_data<=0; @(posedge clk);
    $display("Send bit 2 at %t ns", $time); i_data<=1; @(posedge clk);
    $display("Send bit 3 at %t ns", $time); i_data<=0; @(posedge clk);
    $display("Send bit 4 at %t ns", $time); i_data<=1; @(posedge clk);
    $display("Send bit 5 at %t ns", $time); i_data<=0; @(posedge clk);
    $display("Send bit 6 at %t ns", $time); i_data<=1; @(posedge clk);
    $display("Send bit 7 at %t ns", $time); i_data<=0; @(posedge clk);

    //Parity bit 1
    $display("Send parity bit at %t ns", $time); i_data<=1; @(posedge clk);
    //Stop bit 1
    $display("Send Stop bit at %t ns", $time); i_data<=1;
  
    @(posedge clk);
    temp_out_byte = out_byte;
    
    #1;
    if (temp_out_byte == 8'h55 && done == 1) begin
      $display("PASS: out_byte=%b, done=%b", temp_out_byte, done);
    end else begin
          $display("FAIL: out_byte=%b, done=%b", temp_out_byte, done);
    end
    
    repeat(3) @(posedge clk);

    //===========================================================
    // Test 2 : 8'h1010_1010 + parity bit  1 (PASS)
    // Expect : done = 1 , out_byte = 0xAA
    //===========================================================
    $display();
    $display("\nTest 2 : 8'hAA + parity 1 (PASS)");
    i_data <=1; // IDLE
    @(negedge clk);
    
    
    
    
    //Start bit 0
    i_data<=0; 
    @(posedge clk);
    
    // send 8'h1010_1010 (8'haa)
    $display("Send bit 0 at %t ns", $time); i_data<=0; @(posedge clk);
    $display("Send bit 1 at %t ns", $time); i_data<=1; @(posedge clk);
    $display("Send bit 2 at %t ns", $time); i_data<=0; @(posedge clk);
    $display("Send bit 3 at %t ns", $time); i_data<=1; @(posedge clk);
    $display("Send bit 4 at %t ns", $time); i_data<=0; @(posedge clk);
    $display("Send bit 5 at %t ns", $time); i_data<=1; @(posedge clk);
    $display("Send bit 6 at %t ns", $time); i_data<=0; @(posedge clk);
    $display("Send bit 7 at %t ns", $time); i_data<=1; @(posedge clk);

    //Parity bit 1
    $display("Send parity bit at %t ns", $time); i_data<=1; @(posedge clk);
    //Stop bit 1
    $display("Send Stop bit at %t ns", $time); i_data<=1;
    @(posedge clk);

    temp_out_byte = out_byte;

    #1;
    if (temp_out_byte == 8'hAA && done == 1) begin
      $display("PASS: out_byte=%b, done=%b", temp_out_byte, done);
    end else begin
          $display("FAIL: out_byte=%b, done=%b", temp_out_byte, done);
    end
    
    repeat(3) @(posedge clk);

    //===========================================================
    // Test 3 : 8'h0000_0001 + wrong parity bit 1 (FAIL)
    // Parity should be 0, but intentionally send 1 to fail
    // Expect : done = 0 , out_byte = 0x01
    //===========================================================
    $display();
    $display("\nTest 3 : 8'h01 + parity 1 (FAIL)");
    i_data <=1; // IDLE
    @(negedge clk);
    
    
    //Start bit 0
    i_data<=0; 
    @(posedge clk);
    
    // send 8'h0000_0001 (8'h01)
    $display("Send bit 0 at %t ns", $time); i_data<=1; @(posedge clk);
    $display("Send bit 1 at %t ns", $time); i_data<=0; @(posedge clk);
    $display("Send bit 2 at %t ns", $time); i_data<=0; @(posedge clk);
    $display("Send bit 3 at %t ns", $time); i_data<=0; @(posedge clk);
    $display("Send bit 4 at %t ns", $time); i_data<=0; @(posedge clk);
    $display("Send bit 5 at %t ns", $time); i_data<=0; @(posedge clk);
    $display("Send bit 6 at %t ns", $time); i_data<=0; @(posedge clk);
    $display("Send bit 7 at %t ns", $time); i_data<=0; @(posedge clk);

    //Parity bit 1 (intentionally wrong parity bit)
    $display("Send parity bit at %t ns", $time); i_data<=1; @(posedge clk);
    //Stop bit 1
    $display("Send Stop bit at %t ns", $time); i_data<=1;
    @(posedge clk);
    
    temp_out_byte = out_byte;
    
    #1;
    if (temp_out_byte == 8'h01 && done == 0) begin
      $display("PASS (FAIL case detected): out_byte=%b, done=%b", temp_out_byte, done);
    end else begin
          $display("FAIL: out_byte=%b, done=%b", temp_out_byte, done);
    end
    
    repeat(3) @(posedge clk);

    //=====================================================================
    // Test 4 : 8'h1111_0000 + wrong stop bit (WAIT) then correct stop bit
    // Expect : done = 1, out_byte = 0xf0
    //=====================================================================
    $display();
    $display("\nTest 4 : 8'h01 + parity 1 + wrong stop bit (WAIT test)");
    i_data <= 1; // IDLE
    @(negedge clk);

    // Start bit
    i_data <= 0;
    @(posedge clk);

    // send 8'h1111_0000 (0xF0)
    $display("Send bit 0 at %t ns", $time); i_data <= 0; @(posedge clk);
    $display("Send bit 1 at %t ns", $time); i_data <= 0; @(posedge clk);
    $display("Send bit 2 at %t ns", $time); i_data <= 0; @(posedge clk);
    $display("Send bit 3 at %t ns", $time); i_data <= 0; @(posedge clk);
    $display("Send bit 4 at %t ns", $time); i_data <= 1; @(posedge clk);
    $display("Send bit 5 at %t ns", $time); i_data <= 1; @(posedge clk);
    $display("Send bit 6 at %t ns", $time); i_data <= 1; @(posedge clk);
    $display("Send bit 7 at %t ns", $time); i_data <= 1; @(posedge clk);

    // Parity bit 1
    $display("Send parity bit at %t ns", $time); i_data <= 1; @(posedge clk);

    // wrong stop bit 0 (to enter WAIT)
    $display("Send wrong stop bit at %t ns", $time);
    i_data <= 0;
    @(posedge clk);

    temp_out_byte = out_byte;
    #1; 
    temp_done = done;

    repeat(2) @(posedge clk); 

    // correct stop bit after staying WAIT for three cycels
    $display("Send correct stop bit at %t ns", $time);
    i_data <= 1;

    @(posedge clk);

    #1;
    if (temp_out_byte == 8'hf0 && temp_done == 0) begin
      $display("PASS (STOP_BIT error and output done 0), out_byte : %b , done = %b)", temp_out_byte, temp_done);
    end else begin
      $display("FAIL (STOP_BIT error but output done 1), out_byte : %b , done = %b)", temp_out_byte, temp_done);
    end


    #100;
    
    $display("Finish Simulation at %t ns", $time);
    $finish;
  end
endmodule