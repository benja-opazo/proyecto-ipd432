`timescale 1ns / 1ps


module N_Calculator(length, N, k);

    // Parametros
    parameter N_length = 10;    // Tamaño del bus length en Bits
    parameter N_N = 2;          // Se calcula antes de implementar
    
    localparam Max = 2**N_length - 1; 
    
    // Entradas
    input [N_length-1:0] length;    // Variable que guarda el largo del hash a calcular
    
    // Salidas
    output reg [N_N-1:0] N;     // Cantidad de bloques M
    output reg [8:0] k;         // Cantidad de ceros que se agregan en Padding
    
    // Variables internas
    wire [8:0] x;   // Corresponde a mod(length,512)
    reg aux;
    integer i;
    
    // Instancias
    // Funcion Modulo 512
    mod512 #(.N(N_length)) mod512(
            .length(length),
            .x(x)                   // x = mod(length,512)
        );   
    
    always @(*) begin
        aux = 0;
        k = 0;
        N = 0;
        
        if (x < 9'd448)
            {aux,k} = 10'd447 - {1'b0,x};
        else
            {aux,k} = 10'd959 - {1'b0,x};
        
        for (i = 0; i < Max/512 + 1; i++) begin
            if(length < 448)
                N = 1;
            else if ((448 + i*512 <= length) & (448 + (i + 1)*512 > length)) 
                N = i + 2;
        end
    end
    
endmodule
