`timescale 1ns / 1ps

module Maj(
    input [31:0] X,          
    input [31:0] Y,          
    input [31:0] Z,          
    output [31:0] result 
    );

    assign result = (X & Y) ^ (X & Z) ^ (Z & Y);
        
endmodule
