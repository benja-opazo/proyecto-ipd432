`timescale 1ns / 1ps


module main_hash( 
    input clk,
    // I/O fisico
    input [15:0] SW,
    input BTNC,
    input CPU_RESETN, 
    output [15:0] LED,
    output [7:0] DIS,
    output [7:0] AN,
    // Uart
    input rx,
    output tx
    );
    
    
    // Clock Lentro
    wire clk_1K; // reloj de 1k Hz
    
    // IO
    // Display
    wire [31:0] word;
    
    // Debouncer
    wire [15:0] sw;
    wire btnc;
    wire pre_rst;       // Reset antes de cascada
    wire [21:0] rst;    // Cascada de Reset
    
    // Uart
    // rx
    wire [7:0] rx_data;
    wire rx_ready;
    
    // tx
    wire [7:0] tx_data;
    wire tx_busy;
    wire tx_start;
    
    // Ram Data
    wire d_wea;
    wire [3:0] d_addrw, d_addrr;
    wire [511:0] d_din, d_dout;
    
    // Ram Length
    wire l_wea;
    wire [3:0] l_addrw, l_addrr;
    wire [15:0] l_din, l_dout;
    
    // Driver Ram
    wire driver_start;  // Comienza ejecucion de driver
    wire sha256_data_ready; // Bandera que indica que el dato esta listo para ser leido en sha256 (driver -> sha256)
    
    // Sha256
    wire [255:0] hash;
    wire sha256_hash_ok;    
    wire sha256_start;      // Comienza ejecucion de sha256
    wire sha256_new_data;   // Bandera que pide nuevos datos para sha256 (sha256 -> driver)
    wire sha256_hash_save;  // Bandera que indica que sha256 ya fue calculado
    
    // Instancias
    // Clk
    // Divisor de clk
    ClkDown #(.freq_clock(100_000_000), .freq(1_000)) clockdiv(
        .clk_in(clk),
        .clk_out(clk_1K)
    );
    
    // I/O
    // Debouncers
    debouncer #(.n(16)) deb_sw(
        .clk_in(clk),
        .b_in(SW),
        .d_out(sw)
    );
    
    debouncer #(.n(2)) deb_bot(
        .clk_in(clk),
        .b_in({BTNC, ~CPU_RESETN}),
        .d_out({btnc, pre_rst})
    );
    
    // Cascada de Reset
    FFRst #(.n(21)) m_reset(
        .clk(clk),
        .SRst(pre_rst),
        .FFRst(rst)
    );
    
    
    // Display
    Ssg m_ssg(
        .clk_fast(clk),     // > 1khz    
        .clk_slow(clk_1K),  // 1khz      
        .dot(8'b1111_1111), // agrega punto
        .sel(8'd0),             
        .num_in(word),         
        .ssg_out(DIS),    
        .sel_act(AN)
    );
    
    // Uart Drivers (rx tx)
    uart_rx_driver #(.CLK_FREQUENCY(100_000_000), .BAUD_RATE(115200)) RX (
        .clk(clk),
        .reset(rst[0]),
        .rx(rx),
        .rx_data(rx_data),
        .rx_ready(rx_ready)
    );
    
    uart_tx_driver #(.CLK_FREQUENCY(100_000_000), .BAUD_RATE(115200)) TX (
        .clk(clk),
        .reset(rst[0]),
        .tx(tx),
        .tx_start(tx_start),
        .tx_data(tx_data),
        .tx_busy(tx_busy)
    );
    
    // Rams
    // Ram de datos
    blk_mem_gen_0 DATA(
        .clka(clk),         // input wire clka
        .wea(d_wea),        // input wire [0 : 0] wea
        .addra(d_addrw),    // input wire [3 : 0] addra
        .dina(d_din),       // input wire [511 : 0] dina
        .clkb(clk),         // input wire clkb
        .addrb(d_addrr),    // input wire [3 : 0] addrb
        .doutb(d_dout)      // output wire [511 : 0] doutb
    );
    
    // Ram de largos
    blk_mem_gen_1 LENGTH (
        .clka(clk),         // input wire clka
        .wea(l_wea),        // input wire [0 : 0] wea
        .addra(l_addrw),    // input wire [3 : 0] addra
        .dina(l_din),       // input wire [15 : 0] dina
        .clkb(clk),         // input wire clkb
        .addrb(l_addrr),    // input wire [3 : 0] addrb
        .doutb(l_dout)      // output wire [15 : 0] doutb
    );
     
    // Ram Management
    // Ram Write
    ram_write m_ram_write(      // Guarda en ram de forma ordenada los datos enviados por puerto serial
        .clk(clk),
        .rst(rst[3:1]),
        .rx_ready(rx_ready),
        .rx_data(rx_data),
        .d_wea(d_wea),
        .d_addrw(d_addrw),
        .d_din(d_din),
        .l_wea(l_wea),
        .l_addrw(l_addrw),
        .l_din(l_din)
    );
      
    // Driver de Ram
    driver_ram m_driver_ram(    // Maneja las direcciones de lectura para sha256
        .clk(clk),
        .rst(rst[4]),
        .l_dout(l_dout),                    // Largo del dato que se lee (tambien va al sha256)
        .driver_start(driver_start),        // Bandera que indica a driver_ram que empiece el proceso.
        .new_data(sha256_new_data),         // Bandera que pide nuevos datos para sha256 (sha256 -> driver)
        .hash_ok(sha256_hash_ok),           // Bandera que indica que sha256 esta listo  
        .d_addrr(d_addrr),
        .l_addrr(l_addrr),
        .start(sha256_start),               // Bandera que indica comienzo de calculo de sha256
        .data_ready(sha256_data_ready)      // Bandera que indica que el dato esta listo para ser leido en sha256 (driver -> sha256)
    );

    // Hash
    // Calculo de sha256
    sha256 sha256_calculator(
        .clk(clk),
        .rst(rst[20:5]),
        .length(l_dout[9:0]),
        .hash_save(sha256_hash_save),
        .start(sha256_start),
        .data(d_dout),
        .data_ready(sha256_data_ready),
        .new_data(sha256_new_data),
        .hash(hash),
        .hash_ok(sha256_hash_ok) 
    );
    
    // Display Hash
    display_hash disp_hash(
        .clk(clk),
        .rst(rst[21]),
        .hash(hash),
        .button(btnc),
        .word(word),
        .led(LED[15:13])
    );
    
    // I/O Assign
    assign LED[0] = sha256_hash_ok;
    
    assign driver_start = sw[0];
    assign sha256_hash_save = sw[1];
    
endmodule
