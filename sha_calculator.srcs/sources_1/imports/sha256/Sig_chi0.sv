`timescale 1ns / 1ps

module Sig_chi0(
    input [31:0] X,
    output  [31:0] result 
    );
    
    wire [31:0] X_7, X_18;
    
    RotR #(.n(7)) RotR7 (
        .X(X),
        .X_rot(X_7)
    );
    
     RotR #(.n(18)) RotR18(
          .X(X),
          .X_rot(X_18)
      );
      
     assign result = X_7 ^ X_18 ^ (X >> 3);    
        
endmodule
