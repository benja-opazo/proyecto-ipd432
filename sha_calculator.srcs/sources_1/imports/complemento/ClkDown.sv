`timescale 1ns / 1ps

module ClkDown(
    input clk_in,
    output reg clk_out
    );
    
    reg clk_out_next;
    
    parameter freq_clock=100_000_000;
    parameter freq = 1000_000; // Frecuencia en Hz 
    localparam count_limit = freq_clock/(2*freq); //16'd1/(freq*0.00001));
    
    
    reg [26:0] counter, counter_next;
    
    
    
    
    always @(*) begin
        if (counter == count_limit) begin  counter_next = 0;
                                           clk_out_next = ~clk_out; end
        else begin counter_next = counter + 27'd1;
                   clk_out_next = clk_out; end
    end
    
    always @(posedge clk_in) begin
        counter <= counter_next;
        clk_out <= clk_out_next;
    end
    
endmodule