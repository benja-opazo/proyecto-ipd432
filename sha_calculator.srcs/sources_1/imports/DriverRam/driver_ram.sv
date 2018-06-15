`timescale 1ns / 1ps

module driver_ram(
    input clk,
    input rst,
    input [15:0] l_dout,    // largo del dato que se lee (tambien va al sha256)
    input driver_start,     // Bandera que indica a driver_ram que empiece el proceso.
    input new_data,             // bandera que pide nuevos datos para M (viene de hash)
    input hash_ok,
    output reg [3:0] d_addrr,
    output reg [3:0] l_addrr,
    // Banderas al Hash
    output reg start,           // indica comienzo de calculo de sha256
    output reg data_ready       // bandera que indica que el dato esta listo
    );
    
    localparam IDLE = 3'b000;
    localparam LENGTH = 3'b001;
    localparam START = 3'b010;
    localparam READ = 3'b011;
    localparam R_BUFFER_POST = 3'b100;   // Buffer que da tiempo desde que se envia dato al modulo sha256 y se lee la siguiente memoria de ram
    localparam R_BUFFER = 3'b101;   // Buffer que da tiempo entre que se lee la ram y se envia al modulo sha256
    localparam SEND_TO_HASH = 3'b110;
    
    // Maquina de estados
    reg [2:0] state, state_next;
    
    // Contadores
    reg [15:0] data_count, data_count_next;
    reg  buffer_count, buffer_count_next;
    
    // Tx Uart
    //reg tx_start_next;
    
    // Ram Data
    reg [3:0] d_addrr_next;
    //reg [511:0] data, data_next;
    
    // Ram Length
    reg [3:0] l_addrr_next;
    
    // Flags driver ram
    reg flag_d_read_0, flag_d_read_0_next;    // Flag que indica si se leyo ya en ram de datos o no
    reg flag_l_read_0, flag_l_read_0_next;    // Flag que indica si se leyo ya en ram de largos o no
    
    // flags sha256
    reg start_next, data_ready_next; // Banderas Hash
    reg driver_start_prev;
    
    always @(*) begin
    state_next = state;
    // flags hash256
    start_next = 1'b0;
    data_ready_next = 1'b0;
    // flags driver
    flag_l_read_0_next = flag_l_read_0;
    flag_d_read_0_next = flag_d_read_0;
    //addrs
    l_addrr_next = l_addrr;
    d_addrr_next = d_addrr;
    //contadores
    data_count_next = data_count;
    buffer_count_next = 3'd0;    
    
        case (state)
            IDLE: begin
                if (driver_start & ~driver_start_prev & ~hash_ok) begin // No puede empezar si es que aun no se guarda el ultimo hash calculado
                    data_count_next = 16'b0;
                    state_next = LENGTH;
                end
            end
            LENGTH: begin   // Obtiene el largo del mensaje
                if (~flag_l_read_0) begin
                    l_addrr_next = 4'b0; // Primera lectura
                    flag_l_read_0_next = 1'b1;
                end
                else begin
                    l_addrr_next = l_addrr + 4'b1;
                end
                state_next = START;
            end
            START: begin    
                start_next = 1'b1;
                state_next = READ;
            end
            READ: begin // Lee de ram de datos
                data_count_next = data_count + 16'd512;
                if (~flag_d_read_0) begin
                    d_addrr_next = 4'b0;
                    flag_d_read_0_next = 1'b1;
                end
                else begin
                    d_addrr_next = d_addrr + 4'd1;
                end
                state_next = R_BUFFER;    
            end
            R_BUFFER: begin
                state_next = SEND_TO_HASH;
            end
            SEND_TO_HASH: begin
                if (new_data) begin // espera que sha256 pida nuevos datos
                    data_ready_next = 1'b1; // El dato se entrega al sha256
                    if (data_count >= l_dout)
                        state_next = IDLE;
                    else
                        state_next = R_BUFFER_POST;
                    /*
                    if (hash_ok) state_next = IDLE;
                    else state_next = READ;
                    */
                end
                else begin
                    state_next = SEND_TO_HASH;
                end
            end
            R_BUFFER_POST: begin        // Agrega buffer para cambiar el valor de lectura en ram
                buffer_count_next = buffer_count + 1'b1;
                if (buffer_count == 1'b1) begin
                    state_next = READ;
                end
                else begin
                    state_next = R_BUFFER_POST;
                end
            end
            default: begin
                state_next = IDLE;
            end
        endcase
    end
    
    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            
            start <= 1'b0;
            data_ready <= 1'b0;
            
            flag_l_read_0 <= 1'b0;
            flag_d_read_0 <= 1'b0;
            
            l_addrr <= 4'b0;
            d_addrr <= 4'b0;
            
            data_count <= 16'b0;
            buffer_count <= 1'b0;
            
            driver_start_prev <= 1'b0;
        end 
        else begin
            state <= state_next;
            
            start <= start_next;
            data_ready <= data_ready_next;

            flag_l_read_0 <= flag_l_read_0_next;
            flag_d_read_0 <= flag_d_read_0_next;
            
            l_addrr <= l_addrr_next;
            d_addrr <= d_addrr_next;
            
            data_count <= data_count_next;
            buffer_count <= buffer_count_next;
            
            driver_start_prev <= driver_start;
        end
    
    end
    
endmodule
