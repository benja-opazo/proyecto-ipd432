`timescale 1ns / 1ps


module sha256(clk, rst, length, hash_save, start, data, data_ready, new_data, hash, hash_ok);

    // Parametros
    parameter N_length = 10;   // Tamaño del bus length en Bits
    parameter N_N = 2;         // Tamaño del bus de N en Bits 
    parameter N_MAX = 3;       // Cantidad maxima de iteraciones del Hash en funcion de N_length y N_N
    parameter MAX = 1023;      // Largo maximo del mensaje (2^N_length - 1) 
    
    // Entradas
    input clk;
    input [15:0] rst;
    input hash_save;              // Bandera que indica que el ultimo hash calculado se guardo. Al levantarse el proceso termina y la salida vuelve a su valor por defecto
    input start;                  // Bandera que indica el comienzo del calculo del hash
    input [N_length-1:0] length;  // Variable que guarda el largo del hash a calcular
    input [511:0] data;           // Mensaje que se le calcula el hash, si N_length > 512, entonces se entrega el mensaje de a 512 Bits
    input data_ready;             // Bandera que indica que el valor de data esta listo para ser usado por el modulo
    
    
    // Salidas
    output [255:0] hash;         // Salida de la funcion hash
    output hash_ok;              // Bandera que indica que hash ya fue calculado, y que la salida "hash" ya se puede usar
    output new_data;             // Bandera que indica que el módulo está listo para actualizar "data"
    
    // Variables    
    // Salidas N_calculator
    wire [N_N -1:0] N; // Cantidad de bloques M
    wire [8:0] k;      // Cantidad de ceros que se agregan en Padding
    
    // Salidas padd_calculator
    wire [511:0] M;    // Bloque M, para hashing
    wire ok_padd;      // Bandera que indica que bloque M esta listo
    
    // Salidas hash_manager
    wire new_M;       // Bandera para pedir un nuevo M
    wire start_hash;  // Bandera para partir procedimiento hashing de bloque M
    wire [N_N-1:0] n; // Indice que indica el M a calcular
    
    // Salidas hash_i
    wire [255:0] hash_i;  // Hash obtenido al consumir bloque M
    wire fin_hash_i;      // Bandera que indica que bloque M ha sido digerido

    
    // Instancias
    // Calculo de N y K es un bloque combinacional
    N_Calculator #(.N_length(N_length), .N_N(N_N)) n_calculator(
        .length(length), 
        .N(N),         
        .k(k)   
    );
    
    // Padding. Se rellena con ceros segun un algoritmo, con tal que los bloques M tengan largo multiplo de 512
    Padding #( .N_length(N_length),.N_N(N_N),.N_MAX(N_MAX),.MAX(MAX)) padd_calculator(     
        .clk(clk),
        .rst(rst[1:0]),
        .new_M(new_M),
        .data_ready(data_ready),
        .n(n),
        .N(N),
        .length(length),
        .k(k),
        .data(data),            // Diseñado para 512 bits
        .M(M),
        .ok(ok_padd),
        .new_data(new_data)
    );
    
    // Hash Manager. Administra los modulos internos de sha256
    hash_manager #(.N_N(N_N)) hash_manager(
        .clk(clk),    
        .rst(rst[2]),
        .hash_save(hash_save),
        .start(start),  
        .ok_padd(ok_padd),
        .fin_hash_i(fin_hash_i),
        .hash_i(hash_i),
        .N(N),
        .hash(hash),
        .start_hash(start_hash),
        .new_M(new_M),
        .n(n),
        .hash_ok(hash_ok)
     );
    
     // Hash_i: Realiza el procedimiento hash, para digerir bloque M
     hash_i hash_index(         
         .clk(clk),
         .rst(rst[15:3]),
         .start(start_hash),     
         .M(M), 
         .H_ant(hash),  
         .H(hash_i), 
         .fin(fin_hash_i)          
      );            
endmodule
