`timescale 1ns / 1ps

module ram_write(
    input clk,
    input [2:0] rst,
    input rx_ready,
    input [7:0] rx_data,
    output reg d_wea,
    output reg [3:0] d_addrw,
    output reg [511:0] d_din,
    output reg l_wea,
    output reg [3:0] l_addrw,
    output reg [15:0] l_din
    );
    
    localparam IDLE = 3'b000;
    localparam LENGTH = 3'b001;
    localparam L_BUFFER = 3'b010; // Estado buffer para que los datos de largo se carguen correctamente antes de continuar con el proceso
    localparam PACK = 3'b011;
    localparam WRITE = 3'b100;
    localparam W_BUFFER = 3'b101; // Estado buffer para escritura en ram
    
    // Maquina de estados
    reg [2:0] state, state_next;
    
    // Contadores
    reg [15:0] m_length, m_length_next; // Largo del mensaje, se mide en bits.
    reg [15:0] m_count, m_count_next; // Cuenta cuantos BITS han llegado del mensaje
    
    reg [15:0] p_length, p_length_next; // Largo del paquete que se esta empaquetando, se mide en bits
    reg [15:0] p_count, p_count_next; // Cuenta cuantos bits han llegado del paquete actual
    
    // Flip Flops para la ram de datos
    reg d_wea_next;
    reg [3:0] d_addrw_next;   // Direccion de escritura en ram relativa 
    reg [511:0] d_din_next;
    reg [3:0] d_addrw_abs, d_addrw_abs_next;    //Direccion de escritura en Ram absoluta
        
    // Flip Flops para la ram de datos
    reg l_wea_next;
    reg [3:0] l_addrw_next;   // Direccion de escritura en ram relativa 
    reg [15:0] l_din_next;
    
    // Flags
    reg flag_d_write_0, flag_d_write_0_next;    // Flag que indica si se escribio ya en ram de datos o no
    reg flag_l_write_0, flag_l_write_0_next;    // Flag que indica si se escribio ya en ram de largos o no

    always @(*) begin
        // Valores por defecto
        state_next = state;
        
        m_length_next = m_length;
        m_count_next = m_count;
        
        p_count_next = 16'd0;
        
        d_wea_next = 1'b0;
        d_addrw_next = d_addrw;
        d_din_next = d_din;
        
        l_wea_next = 1'b0;
        l_addrw_next = l_addrw;
        l_din_next = 16'd0;
        
        flag_d_write_0_next = flag_d_write_0;
        flag_l_write_0_next = flag_l_write_0;
        
        // Calculo de cantidad de baudios que faltan para terminar el paquete
        if (m_length - m_count >= 16'd512) p_length_next = 16'd512;
        else p_length_next = m_length - m_count;
    
        case (state)
            IDLE: begin // Espera la llegada de un rx_data
            m_length_next = 16'd0;  // Borra el largo guardado del mensaje
            m_count_next = 16'd0;   // Comienza a escribir un mensaje desde 0 (la primera vez que llega a WRITE, en ram hay 8 bits escritos)
                if (rx_ready) begin
                    d_din_next = 512'd0;  // Borra el mensaje guardado anteriormente
                    m_length_next[7:0] = rx_data;
                    state_next = LENGTH;
                end
            end
            LENGTH: begin   // Recibe el segundo mensaje que dice el largo en bits del mensaje que va a llegar
                if (rx_ready) begin
                    m_length_next[15:8] = rx_data;
                    state_next = L_BUFFER;
                end
            end
            L_BUFFER: begin
                state_next = PACK;
            end
            PACK: begin // Empaqueta los mensajes en paquetes de 512 bits
                if (p_count >= p_length) begin  // Ya llego el paquete completo, y se puede escribir en ram
                    m_count_next = m_count + p_count;
                    d_din_next = d_din << 16'd512 - p_count;  // De esta forma si el paquete es mas corto de 512, los dont care quedan a la izquierda
                    state_next = WRITE;
                end
                else begin  // Proceso de empaquetamiento
                    p_count_next = p_count;
                    if (rx_ready) begin
                        d_din_next = {d_din[503:0],rx_data};
                        p_count_next = p_count + 16'd8;
                    end
                    state_next = PACK;
                end
            end
            WRITE: begin    // Escritura en ram
                flag_d_write_0_next = 1'b1;   // La primera vez que se entra al estado, flag_write_0 se cambia a 1
                // Ram de Datos
                d_wea_next = 1'b1;
                
                if (~flag_d_write_0) d_addrw_next = 4'b0;  // Si es primera vez que se escribe, se mantiene la direccion en 0
                else d_addrw_next = d_addrw + 4'b1;
                
                if (m_count >= m_length) begin
                    flag_l_write_0_next = 1'b1;
                    // Ram de Largos
                    l_wea_next = 1'b1;
                    l_din_next = m_length;
                    
                    if (~flag_l_write_0) l_addrw_next = 4'b0;  // Si es primera vez que se escribe, se mantiene la direccion en 0
                    else l_addrw_next = l_addrw + 4'b1;
                
                    state_next = IDLE; // Si ya se escribio el mensaje completo, se termina el proceso
                end
                else begin
                    state_next = W_BUFFER; // Si aun faltan paquetes por llegar, se continua empaquetando
                end
            end
            W_BUFFER: begin
                d_din_next = 512'd0;
                state_next = PACK;
            end
            default: begin
                state_next = IDLE;
            end
        endcase
    end
    
    always @(posedge clk) begin
        // Se separan los reset por el gran fanout que habia originalmente
        if (rst[0]) begin
            state <= IDLE;
                    
            m_length = 16'd0;
            m_count <= 16'd0;
            
            p_count <= 16'd0;
            p_length <= 16'd0;
        end
        else begin
            state <= state_next;
                    
            m_length <= m_length_next;
            m_count <= m_count_next;
            
            p_count <= p_count_next;
            p_length <= p_length_next;
        end
        
        if (rst[1]) begin
            d_addrw <= 4'd0;
            d_wea <= 1'b0;
            
            
            l_addrw <= 4'd0;
            l_wea <= 1'b0;
            l_din <= 16'd0;
            
            flag_d_write_0 <= 1'b0;
            flag_l_write_0 <= 1'b0;  
        end
        else begin
            d_addrw <= d_addrw_next;
            d_wea <= d_wea_next;
            
            l_addrw <= l_addrw_next;
            l_wea <= l_wea_next;
            l_din <= l_din_next;
            
            flag_d_write_0 <= flag_d_write_0_next;
            flag_l_write_0 <= flag_l_write_0_next;
        end
        
        if (rst[2]) begin
            d_din <= 512'd0;
        end
        else begin
            d_din <= d_din_next;
        end
    end
    
endmodule
