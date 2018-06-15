`timescale 1ns / 1ps

module display_hash(
    input clk,
    input rst,
    input [255:0] hash,
    input button,
    output reg [31:0] word,
    output reg [2:0] led
    );
    
    reg button_ant;
    reg [31:0] word_next;
    reg [2:0] led_next;
    
    always @(*) begin
        word_next = word;
        led_next = led;
        
        if (button & ~button_ant) led_next = led + 3'd1;
        
        case(led)
            3'd7: word_next = hash[31:0];
            3'd6: word_next = hash[63:32];
            3'd5: word_next = hash[95:64];
            3'd4: word_next = hash[127:96];
            3'd3: word_next = hash[159:128];
            3'd2: word_next = hash[191:160];
            3'd1: word_next = hash[223:192];
            3'd0: word_next = hash[255:224];
            default: word_next = 32'd0;              
        endcase
    end

    always@ (posedge clk) begin
        button_ant <= button;
        if (rst) begin
            led <= 3'd0;
            word <= 32'd0;
        end
        else begin 
            led <= led_next;
            word <= word_next;
        end
    end

endmodule
