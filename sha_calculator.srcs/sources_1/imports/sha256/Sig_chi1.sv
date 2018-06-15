`timescale 1ns / 1ps

module Sig_chi1(
    input [31:0] X,
    output [31:0] result 
    );
    
    wire [31:0] X_17,X_19;
    
    RotR #(.n(17)) RotR17 (
        .X(X),
        .X_rot(X_17)
    );
    
     RotR #(.n(19)) RotR19(
          .X(X),
          .X_rot(X_19)
      );
      
    assign result = X_17 ^ X_19 ^ (X >> 10);    
        
endmodule
