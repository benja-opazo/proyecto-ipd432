`timescale 1ns / 1ps


module mod512(length, x);
    
    // Parametros
    parameter N = 10;
    
    localparam Max=2**N - 1;
    
    // Entradas
    input [N-1:0] length;
    
    // Salidas
    output [8:0] x;  
    
    // Variables Internas
    reg [N:0] x_aux;
    integer i;
    
    assign x = x_aux[8:0];
    
    always @(*) begin
        x_aux = {N{1'b0}};
        
        for (i = 0; i < Max/512 + 1; i++) begin
            if ((i*512 < length) && (length < (i + 1)*512)) 
                x_aux = {1'b0,length} - i*512;
        end
    end
    
endmodule
