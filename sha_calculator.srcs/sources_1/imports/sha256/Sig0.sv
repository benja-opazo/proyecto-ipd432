`timescale 1ns / 1ps

module Sig0(
    input [31:0] X,
    output [31:0] result 
    );
    
    wire [31:0] X_2,X_13,X_22;
    
    RotR #(.n(2)) RotR2 (
        .X(X),
        .X_rot(X_2)
    );
    
    RotR #(.n(13)) RotR13(
        .X(X),
        .X_rot(X_13)
    );
      
      
    RotR #(.n(22)) RotR22 (
        .X(X),
        .X_rot(X_22)
    );
    
    assign result = X_22 ^ X_2 ^ X_13;    
        
endmodule
