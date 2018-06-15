`timescale 1ns / 1ps

module main_sim();
    // IO Main
    logic clk, pre_rst;
    
    // RAM datos
    logic [3:0] d_addrr;
    logic [511:0] d_dout;
    
    // RAM largos
    logic [3:0] l_addrr;
    logic [15:0] l_dout; 
    
    // driver_ram
    logic driver_start;
    
    // sha256
    logic sha256_new_data, sha256_hash_ok, sha256_start, sha256_data_ready;
    logic hash_save;
    logic [255:0] hash;
    
    // Reset
    logic [21:0] rst;
    
    // Reset
    FFRst #(.n(21)) DUT0(
        .clk(clk),
        .SRst(pre_rst),
        .FFRst(rst)
    );
    
    driver_ram DUT1(    // Maneja las direcciones de lectura para sha256
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
    
    sha256 DUT2(
        .clk(clk),
        .rst(rst[20:5]),
        .length(l_dout[9:0]),
        .hash_save(hash_save),
        .start(sha256_start),
        .data(d_dout),
        .data_ready(sha256_data_ready),
        .new_data(sha256_new_data),
        .hash(hash),
        .hash_ok(sha256_hash_ok) 
    );
     
 // Ram largos
 
    always begin
        #5
        case (l_addrr)
            4'd0: l_dout = 16'd520;
            4'd1: l_dout = 16'd528;
            4'd2: l_dout = 16'd520;
            4'd3: l_dout = 16'd8;
            4'd4: l_dout = 16'd0;
            4'd5: l_dout = 16'd0;
            4'd6: l_dout = 16'd0;
            4'd7: l_dout = 16'd0;
            4'd8: l_dout = 16'd0;
            4'd9: l_dout = 16'd0;
            4'd10: l_dout = 16'd0;
            4'd11: l_dout = 16'd0;
            4'd12: l_dout = 16'd0;
        endcase
    end
    
    // Ram datos
    always begin
        #5
        case (d_addrr)
            4'd0: d_dout = ~512'h00;
            4'd1: d_dout = 512'h00;
            4'd2: d_dout = 512'h01;
            4'd3: d_dout = ~512'h00;
            4'd4: d_dout = 512'h02;
            4'd5: d_dout = 512'h03;
            4'd6: d_dout = 512'h0;
            4'd7: d_dout = 512'h0;
            4'd8: d_dout = 512'h0;
            4'd9: d_dout = 512'h0;
            4'd10: d_dout = 512'h0;
            4'd11: d_dout = 512'h0;
            4'd12: d_dout = 512'h0;
        endcase
    end   

 // Fin Ram_datos
    initial begin
        // Reseteo de datos
        clk = 0;
        pre_rst = 0;
        
        d_dout = 0;
        l_dout = 0;
        
        driver_start = 0;
        hash_save = 0;
        
        // Logica simulada de reset
        while (rst != {21{1'b0}}) begin
            #10 pre_rst = 0;
        end
        
        #10 pre_rst = 1;
        
        while (rst != {21{1'b1}}) begin
            #10 pre_rst = 1;
        end
        
        #10 pre_rst = 0;
        while (rst != {21{1'b0}}) begin
            #10 pre_rst = 0;
        end
        
        #20
        
        // Inicio Hash
        #10 driver_start = 1;
        #20 driver_start = 0;
        
        while (sha256_hash_ok == 0) begin
            #10 hash_save = 0;
        end
        
        #10 hash_save = 1;
        #20 hash_save = 0;
        //
        
        #10 driver_start = 1;
        #20 driver_start = 0;
        
        while (sha256_hash_ok == 0) begin
            #10 hash_save = 0;
        end
        
        #10 hash_save = 1;
        #10 hash_save = 0;
        
        #10 driver_start = 1;
        #20 driver_start = 0;
        
        while (sha256_hash_ok == 0) begin
            #10 hash_save = 0;
        end
        
        #10 hash_save = 1;
        #10 hash_save = 0;
/*
        // Reset
        #10 pre_rst = 1;
        #50 pre_rst = 0;
*/
        //
        #10 driver_start = 1;
        #20 driver_start = 0;
        
        while (sha256_hash_ok == 0) begin
            #10 hash_save = 0;
        end
        
        #10 hash_save = 1;
        #10 hash_save = 0;
        
        #10 driver_start = 1;
        #20 driver_start = 0;
        
        while (sha256_hash_ok == 0) begin
            #10 hash_save = 0;
        end
        
        #10 hash_save = 1;
        #10 hash_save = 0;
        
     end
     
     always #5 clk = ~clk;

endmodule
