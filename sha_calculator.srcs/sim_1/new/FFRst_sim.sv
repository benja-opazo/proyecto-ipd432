`timescale 1ns / 1ps

module FFRst_sim();
    // IO Main
    logic clk, SRst;
    logic [10:0] FFRst;
    
    FFRst #(.n(10)) DUT(clk, SRst, FFRst);
    
     // Fin Ram_datos
       initial begin
           // Reseteo de datos
           clk = 0;
           SRst = 0;
           
           #100         // Prueba que se activan todas las señales de reset
           SRst = 1;
           
           #200         // Prueba que se desactivan todas las señales de reset
           SRst = 0;
           
           #200         // Prueba que las señales de reset se desactivan luego de que se activen TODAS
           SRst = 1;
           #10
           SRst = 0;
           
           #220         // Prueba que funciona bien incluso con glitches en la entrada
           SRst = 1;
           #10
           SRst = 0;
           #10
           SRst = 1;
           
           #200         // Prueba que las señales de reset se activan luego de que se desactiven TODAS
           SRst = 0;
           #10
           SRst = 1;
        end
        
        always #5 clk = ~clk;
    
    
endmodule
