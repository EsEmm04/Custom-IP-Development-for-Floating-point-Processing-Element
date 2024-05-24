`timescale 1ns / 1ps
`define N 2
//This is the size of array we are passing through test bench. Be careful to change the same. 
`define S 32 'b 0_10000010_01000000000000000000000
//This is the size initial number stored in PE. Be careful to change the same. 


module PE(input [31:0] P[0:	`N-1],input [31:0] Q[0:`N-1], output reg [31:0] R);
  
  reg [31:0]pro[0:`N-1];
  //Stores product of same index of arrays. 
  reg [31:0]sum[0:`N-2];
  //stores sum until that index.
  
  genvar i,j;
  
  //If there is only one element in the arrays.
  if(`N==1)
    begin
      FloatingMultiplication P9(P[0],Q[0],pro[0]);
      FloatingAddition Q1(pro[0],`S,R); 
    end
  
  else 
    begin
      
  // Floating Point Multiplication at each index of arrays.
  for(i=0;i<`N;i=i+1)
    begin
      FloatingMultiplication P2(P[i],Q[i],pro[i]);
    end
      
 // Addition of product of 0th and 1st element of arrays. 
  FloatingAddition P1(pro[0],pro[1],sum[0]); 
  

  // Addition of product of same index of arrays until index j.      
    for(j=2;j<`N;j=j+1)
  begin  
    FloatingAddition P3(pro[j],sum[j-2],sum[j-1]);
  end
 
      // Final result of PE.
      FloatingAddition P4(sum[`N-2],`S,R);

 end
  
endmodule
  
//This module is floating point Multiplication it multiplies two numbers in IEEE 754 standard and return result in IEEE 754 single precision. 

module FloatingMultiplication
  (input [31:0]A,
   input [31:0]B,
   output reg  [31:0] result);

reg [23:0] A_Mantissa,B_Mantissa;
reg [22:0] Mantissa;
reg [47:0] Temp_Mantissa;
reg [7:0] A_Exponent,B_Exponent,Temp_Exponent,diff_Exponent,Exponent;
reg A_sign,B_sign,Sign;
reg [32:0] Temp;
reg [6:0] exp_adjust;
  
  
always@(*)
begin

//Extracting sign, Exponent, Mantissa from both the numbers.
A_Mantissa = {1'b1,A[22:0]};
A_Exponent = A[30:23];
A_sign = A[31];
  
B_Mantissa = {1'b1,B[22:0]};
B_Exponent = B[30:23];
B_sign = B[31];
  
// Bias for single precision is 127, so obtaining temporary exponent and mantissa for our result.
Temp_Exponent = A_Exponent+B_Exponent-127;
  
Temp_Mantissa = A_Mantissa*B_Mantissa;
  
  //If Temp_Mantissa[47]==1 that means our actual mantissa is from [46:24] and 1 will be added exponent else our exponent remains the same and original mantissa lies in [45:23].
  
Mantissa = Temp_Mantissa[47] ? Temp_Mantissa[46:24] : Temp_Mantissa[45:23];
  
Exponent = Temp_Mantissa[47] ? Temp_Exponent+1'b1 : Temp_Exponent;

//To find the sign of our result it is just XOR of sign of A and B.  
  
Sign = A_sign^B_sign;
  
//Final result in IEEE 754 standard.  
  
result = {Sign,Exponent,Mantissa};
  
end
  
endmodule


//This module is floating point addition it adds two 32 bit numbers in IEEE 754 standard and return result in IEEE 754 single precision. 

module FloatingAddition
  (input [31:0]A,
   input [31:0]B,
   output reg  [31:0] result);

reg [23:0] A_Mantissa,B_Mantissa;
reg [23:0] Temp_Mantissa;
reg [22:0] Mantissa;
reg [7:0] Exponent;
reg Sign;
wire MSB;
reg [7:0] A_Exponent,B_Exponent,Temp_Exponent,diff_Exponent;
reg A_sign,B_sign,Temp_sign;
reg [32:0] Temp;
reg carry;

reg comp;
reg [7:0] exp_adjust;
  
  
always @(*)
begin

  // Determining which one of A and B has greater exponent.
comp =  (A[30:23] >= B[30:23])? 1'b1 : 1'b0;
  
//A_Mantissa,A_Exponent, A_sign stores Mantissa,Exponent,Sign of greater number among A and B.
A_Mantissa = comp ? {1'b1,A[22:0]} : {1'b1,B[22:0]};
A_Exponent = comp ? A[30:23] : B[30:23];
A_sign = comp ? A[31] : B[31];
    
//B_Mantissa,B_Exponent, B_sign stores Mantissa,Exponent,Sign of smaller number among A and B.
B_Mantissa = comp ? {1'b1,B[22:0]} : {1'b1,A[22:0]};
B_Exponent = comp ? B[30:23] : A[30:23];
B_sign = comp ? B[31] : A[31];
 
 //If both numbers A and B are equal in magnitude and opposite in sign , their addition gives 0.
  if (A[30:0] == B[30:0] && A[31] != B[31]) begin
            result <= 0;
        end
  else 
    begin

      //Gives difference of maximum and minimum exponents.
diff_Exponent = A_Exponent-B_Exponent;
      
  //Mantissa of smaller number is shifted by the difference of their exponents.
B_Mantissa = (B_Mantissa >> diff_Exponent);
      
//This calculates the sum or difference of mantissas depending on the sign difference between A and B. If A_sign is different from B_sign, it adds the mantissas (A_Mantissa + B_Mantissa). Otherwise, it subtracts (A_Mantissa - B_Mantissa). The result is stored in Temp_Mantissa, and carry indicates if there was a carry-out during addition or borrow during subtraction.      
  
{carry,Temp_Mantissa} =  (A_sign ~^ B_sign)? A_Mantissa + B_Mantissa : A_Mantissa-B_Mantissa ;

//This line initializes exp_adjust with the exponent of A (A_Exponent). This variable will be adjusted later based on the result of addition or subtraction.      
  
exp_adjust = A_Exponent;

// If there was a carry (carry is true), it indicates overflow during addition. In this case, Temp_Mantissa is right-shifted by 1 bit to normalize it, and exp_adjust is incremented by 1 to adjust the exponent.
      
if(carry)
    begin
        Temp_Mantissa = Temp_Mantissa>>1;
        exp_adjust = exp_adjust+1'b1;
    end
      
else 
 //When there was no carry, it implies no overflow, so it enters a loop (while) to left-shift Temp_Mantissa and decrement exp_adjust until the leading bit (bit 23) of Temp_Mantissa becomes 1, effectively normalizing the mantissa.
    
  begin
    while(!Temp_Mantissa[23])
        begin
           Temp_Mantissa = Temp_Mantissa<<1;
           exp_adjust =  exp_adjust-1'b1;
        end
    end
 
//Sign of greater number.      
Sign = A_sign;
  
Mantissa = Temp_Mantissa[22:0];
  
Exponent = exp_adjust;
  
      //Final result of floatiung point addition of two IEEE 754 32 bits number. 
result = {Sign,Exponent,Mantissa};
    end
end
endmodule