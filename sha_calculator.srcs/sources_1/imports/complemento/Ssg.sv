`timescale 1ns / 1ps

module Ssg(
    input clk_fast, // > 1khz
    input clk_slow, // 1khz
    input [7:0] dot, // agrega punto al ssg
    input [7:0] sel,
    input [31:0] num_in,
    output reg [7:0] ssg_out,
    output reg [7:0] sel_act
    );
    
    reg [7:0] sel_rotador;
    reg [7:0] sel_rotador_next = 8'b0000_0001; // Rota 8'b0000_0001
    
    reg [7:0] sel_act_next; //ssg que se mostrara
    
    reg [3:0] num_show, num_show_next; // Numero que se muestra segun sel_act
    
    reg dot_show, dot_show_next; // punto que se muestra segun sel_act
    
    reg [7:0] ssg_out_next;
        
    always @(*) begin
        if (sel_rotador != 8'b0111_1111)
            sel_rotador_next = (sel_rotador << 1) | 8'b0000_0001;
        else
            sel_rotador_next = 8'b1111_1110;
    end
    
    always @(*) begin
    //sel_act logic
        sel_act_next = sel_rotador | sel;
    end
    
    always @(*) begin
    //num_in logic
        case (sel_act)
            8'b1111_1110: begin num_show_next = num_in[3:0];
                                dot_show_next = dot[0]; end 
            8'b1111_1101: begin num_show_next = num_in[7:4];
                                dot_show_next = dot[1]; end
            8'b1111_1011: begin num_show_next = num_in[11:8];
                                dot_show_next = dot[2]; end
            8'b1111_0111: begin num_show_next = num_in[15:12];
                                dot_show_next = dot[3]; end
            8'b1110_1111: begin num_show_next = num_in[19:16];
                                dot_show_next = dot[4]; end
            8'b1101_1111: begin num_show_next = num_in[23:20];
                                dot_show_next = dot[5]; end
            8'b1011_1111: begin num_show_next = num_in[27:24];
                                dot_show_next = dot[6]; end
            8'b0111_1111: begin num_show_next = num_in[31:28];
                                dot_show_next = dot[7]; end
            default: begin      num_show_next = 8'b1111_1111;
                                dot_show_next = 1'b1; end
        endcase
    end
    
    always @(*) begin
    // Display logic
        case (num_show)
            4'd0: ssg_out_next = {7'b0000_001,dot_show};
            4'd1: ssg_out_next = {7'b1001_111,dot_show};
            4'd2: ssg_out_next = {7'b0010_010,dot_show};
            4'd3: ssg_out_next = {7'b0000_110,dot_show};
            4'd4: ssg_out_next = {7'b1001_100,dot_show};
            4'd5: ssg_out_next = {7'b0100_100,dot_show};
            4'd6: ssg_out_next = {7'b0100_000,dot_show};
            4'd7: ssg_out_next = {7'b0001_111,dot_show};
            4'd8: ssg_out_next = {7'b0000_000,dot_show};
            4'd9: ssg_out_next = {7'b0001_100,dot_show};
            4'd10: ssg_out_next = {7'b0001_000,dot_show};
            4'd11: ssg_out_next = {7'b1100_000,dot_show};
            4'd12: ssg_out_next = {7'b0110_001,dot_show};  //c
            4'd13: ssg_out_next = {7'b1000_010,dot_show};  //d
            4'd14: ssg_out_next = {7'b0110_000,dot_show}; //e
            4'd15: ssg_out_next = {7'b0111_000,dot_show};  //f
            default: ssg_out_next = 8'b1111_1111; 
        endcase
        
    end
    
    always @(posedge clk_fast) begin
        sel_act <= sel_act_next;
        num_show <= num_show_next;
        ssg_out <= ssg_out_next;
        dot_show <= dot_show_next;     
    end
    
    always @(posedge clk_slow) begin
        sel_rotador <= sel_rotador_next;     
    end
endmodule