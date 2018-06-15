`timescale 1ns / 1ps

module uart_rx_driver (
	input clk,
	input reset,
	input rx,
	output [7:0] rx_data,
	output reg rx_ready
    );
    
    parameter CLK_FREQUENCY = 100000000;
    parameter BAUD_RATE = 115200;
    
    //Variables
        
    // Desconocidas, pero necesarias
    wire baud8_tick;    
    reg rx_ready_sync;
    wire rx_ready_pre;
        
    //Instancias
    
    // Tick generator
    uart_baud_tick_gen #(.CLK_FREQUENCY(CLK_FREQUENCY), .BAUD_RATE(BAUD_RATE), .OVERSAMPLING(8))
    baud8_tick_blk (
        .clk(clk),
        .enable(1'b1),
        .tick(baud8_tick)
    );

    // Rx block
    uart_rx uart_rx_blk (
        .clk(clk),
        .reset(reset),
        .baud8_tick(baud8_tick),
        .rx(rx),
        .rx_data(rx_data),
        .rx_ready(rx_ready_pre)
    );

    always @(posedge clk) begin
        rx_ready_sync <= rx_ready_pre;
        rx_ready <= ~rx_ready_sync & rx_ready_pre;
    end
    
endmodule