`timescale 1ns / 1ps

module FFRst(clk, SRst, FFRst);

    // Parametros
    parameter n = 10;   // Cantidad de resets

    // Entradas
    input clk;
    input SRst;         // Reset sincronico
    
    // Salidas
    output reg [n:0] FFRst; // Multiples reset en cascada
    
    // Variables auxiliares
    reg [n:0] FFRst_next = 0;
    
    // Para el ciclo for
    integer i;

    always @(*) begin
        if (FFRst == {n+1{1'b0}} | FFRst == {n+1{1'b1}}) begin
                FFRst_next[0] = SRst;
        end 
                
        for (i = 1; i <= n; i++) begin
            FFRst_next[i] = FFRst[i-1];
        end
    end
    
    always @(posedge clk) begin
            for (i = 0; i <= n; i++) begin
                FFRst[i] <= FFRst_next[i];
            end
    end
        
/*    
    always @(*) begin 
        FFRst_next = {n+1{SRst}};
    end
  
    always @(posedge clk) begin
        FFRst <= FFRst_next;
    end
*/
/*    
    always @(*) begin
        FFRst_next[0] = SRst;
        for (i = 1; i <= n; i++) begin
            FFRst_next[i] = FFRst[i-1];
        end
    end
    
    always @(posedge clk) begin
        for (i = 0; i <= n; i++) begin
            FFRst[i] <= FFRst_next[i];
        end
    end
*/  
endmodule
