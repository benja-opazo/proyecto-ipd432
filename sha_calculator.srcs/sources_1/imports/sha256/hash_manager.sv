`timescale 1ns / 1ps


module hash_manager(clk, rst, hash_save, start, ok_padd, fin_hash_i, hash_i, N, hash, start_hash, new_M, n, hash_ok);

    // Parametros
    parameter N_N = 2;                   
    
    // Entradas
    input clk;       
    input rst;
    input hash_save;            // Bandera que indica que el ultimo hash calculado se guardo. Al levantarse el proceso termina y la salida vuelve a su valor por defecto
    input start;                // Bandera que indica que parta el hashing total   
    input ok_padd;              // Bandera que indica que el bloque M esta listo para ejecutar
    input fin_hash_i;           // Bandera que indica termino de hashing de bloque M
    input [255:0] hash_i;       // Resultado de hash_i
    input [N_N-1:0] N ;         // Cantidad de iteraciones  
    
    // Salidas
    output reg [255:0] hash ;   // Hash final que va a la salida, entra al modulo hash_i como hash_ant
    output reg start_hash ;     // Bandera que indica al modulo hash_i que inicie
    output reg new_M ;          // Bandera que pide un bloque M nuevo
    output reg [N_N-1:0] n ;    // Indice de iteracion
    output reg hash_ok ;        // Bandera de termino de hashing completo       
                  
    
    // Estados
    localparam IDLE=2'd0;
    localparam NEW_M = 2'd1;
    localparam HASHING = 2'd2;
    localparam FIN = 2'd3;
    
    // Variables internas
    
    // Variables maquina de estados
    reg [1:0] state;
    reg [1:0] state_next;
    
    // Detectos de cambio
    reg start_ant;
    
    
    // Salidas flip-flop
    reg [255:0] hash_next;
    reg new_M_next;
    reg [N_N-1:0] n_next;
    reg hash_ok_next;
    reg start_hash_next;
    
    always @(*) begin
        state_next = state;
    
        hash_next = hash;
        n_next = n;    
        
        new_M_next = new_M;     // Se mantiene hasta que llegue el OK
        start_hash_next = 1'b0; // En cero por defecto
        hash_ok_next = hash_ok; // Se mantiene por defecto
        
        case(state)
            IDLE: begin
                // Asignacion de valores iniciales
                n_next=1'b1;
                new_M_next=1'b0;
                hash_ok_next = 1'b0;
                hash_next = {32'h6a09e667,32'hbb67ae85,32'h3c6ef372,32'ha54ff53a    // Valor entregado por el algoritmo   
                         ,32'h510e527f,32'h9b05688c,32'h1f83d9ab,32'h5be0cd19};
                
                if(start & ~ start_ant)
                    state_next = NEW_M;
            end
            NEW_M: begin
                new_M_next = 1'b1;
                
                if (ok_padd) begin
                    new_M_next = 1'b0;
                    state_next = HASHING;                   
                end
            end
            HASHING: begin
                start_hash_next = 1'b1;

                if (fin_hash_i) begin       // Bandera de termino hash_i alta
                    hash_next = hash_i;     // Guarda hash nuevo calculado
                    if (n == N)
                        state_next = FIN;
                    else begin
                        state_next = NEW_M;
                        n_next = n +1;                    
                    end
                end
            end
            FIN: begin
                hash_ok_next = 1'b1;
                if (hash_save) state_next = IDLE;
            end  
        endcase
    end
    
    always @(posedge clk) begin
        start_ant <= start;
        if (rst) begin
            new_M <= 1'b0;
            n <= 1;
            
            state <= IDLE;
            hash <= {32'h6a09e667,32'hbb67ae85,32'h3c6ef372,32'ha54ff53a                  
                     ,32'h510e527f,32'h9b05688c,32'h1f83d9ab,32'h5be0cd19}; //H(0) fijo dado por el algoritmo  
            
            start_hash<= 1'b0;
            hash_ok <= 1'b0;
        end
        else begin
            new_M      <= new_M_next;
            n          <= n_next;
            state      <= state_next;
            hash       <= hash_next;
            start_hash <= start_hash_next;
            hash_ok    <= hash_ok_next;
        end
    end    
endmodule
