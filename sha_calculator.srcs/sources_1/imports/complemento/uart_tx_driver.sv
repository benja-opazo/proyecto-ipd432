`timescale 1ns / 1ps

module uart_tx_driver(
    input clk,
	input reset,
    output tx,
	input tx_start,
	input [7:0] tx_data,
	output tx_busy
    );
    
    parameter CLK_FREQUENCY = 100000000;
    parameter BAUD_RATE = 115200;
    
    wire baud_tick;
    
    uart_baud_tick_gen #(.CLK_FREQUENCY(CLK_FREQUENCY), .BAUD_RATE(BAUD_RATE), .OVERSAMPLING(1))
    baud_tick_blk (
        .clk(clk),
        .enable(tx_busy),
        .tick(baud_tick)
    );
    
    uart_tx uart_tx_blk (
        .clk(clk),
        .reset(reset),
        .baud_tick(baud_tick),
        .tx(tx),
        .tx_start(tx_start),
        .tx_data(tx_data),
        .tx_busy(tx_busy)
    );
    
endmodule