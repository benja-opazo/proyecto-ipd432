`timescale 1ns / 1ps

module debouncer(clk_in, b_in, d_out);
    parameter n = 1; //Bus length
    input clk_in;
    input [n-1:0] b_in; //bounced signal
    output reg [n-1:0] d_out; //debounced signal
    
    reg [n-1:0] q1; //salida flip flop 1
    reg [n-1:0] q1_next = {n{1'b0}};
    reg [n-1:0] q2; //salida flip flop 2
    reg [n-1:0] q2_next = {n{1'b0}};
    
    reg [n-1:0] d_out_next;
    
    reg [15:0] contador, contador_next;
    
    localparam cont_lim = 16'd50000;
    
    always @(*) begin
        contador_next = 16'd0; // Valor por defecto
    
        q1_next = b_in;
        q2_next = q1;
        
        if (contador < cont_lim) begin
            d_out_next = d_out;     // La salida no cambia
            if (q2 == b_in)  // Si el flip flop es igual a la entrada en dos cantos consecutivos avanza timer
                contador_next = contador + 16'd1;
        end
        else    //Si la entrada es estable 10ms la salida cambia
            d_out_next = b_in;
    end
    
    always @(posedge clk_in) begin
        q1 <= q1_next; //ff 1
        q2 <= q2_next; //ff 2
        contador <= contador_next;
        d_out <= d_out_next;
    end
    
endmodule