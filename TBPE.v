`timescale 1ns / 1ps
`define N 2
//This is the size of array we are passing through test bench. Be careful to change the same 

module TB;
  reg [31:0] A [0:`N-1]; //Input array of N elements A.
  reg [31:0] B [0:`N-1]; //Input array of N elements B.
  wire [31:0] result; //Output of PE.
  
  PE F_Add (A,B,result); //DUT Instantiation.

initial  
begin
  
  //Stimulus generation

  A[0] = 32'b0_01111111_10000000000000000000000;  // 1.5
  B[0] = 32'b1_10000000_10000000000000000000000;  // -3.0
  
  #100
  
  A[1] = 32'b1_10000000_01100000000000000000000;  //-2.75
  B[1] = 32'b0_10000000_00000000000000000000000;  // 2.0
  
// Input elements of array A and B.
  
end

initial
begin

#600
  $display(" Result : %b",result);
  //Displaying the final output of PE.
#600

$finish;
end
endmodule