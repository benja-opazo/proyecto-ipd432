`timescale 1ns / 1ps

module Sig1(
    input [31:0] X,
    output [31:0] result 
    );
    
    wire [31:0] X_6,X_11,X_25;
    
    RotR #(.n(6)) RotR6 (
        .X(X),
        .X_rot(X_6)
    );
    
    RotR #(.n(11)) RotR11(
        .X(X),
        .X_rot(X_11)
    );
      
      
    RotR #(.n(25)) RotR25 (
        .X(X),
        .X_rot(X_25)
    );
    
    assign result = X_6 ^ X_11 ^ X_25;    
        
endmodule