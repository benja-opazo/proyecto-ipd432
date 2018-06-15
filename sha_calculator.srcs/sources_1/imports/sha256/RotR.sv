`timescale 1ns / 1ps

// Rotacion Circular
module RotR( 
    input [31:0] X,
    output  [31:0] X_rot
    );
    
    parameter n = 2;  // No puede ser cero
    
    assign X_rot = {X[n-1:0], X[31:n]};
endmodule
