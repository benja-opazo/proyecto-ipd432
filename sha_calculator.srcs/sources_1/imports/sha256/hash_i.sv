`timescale 1ns / 1ps



module hash_i( 
    
    input clk,
    input [12:0] rst,
    input start,            // Bandera que indica inicio de calculo de H(t)
    input [511:0] M,        // Registro de 512 bits
    input [255:0] H_ant,    // H(t-1)
    output reg [255:0] H,   // H(t)
    output reg fin          // Bandera de termino (dura un ciclo)
    );
    
    // Parametros maquina de estados
    localparam IDLE = 3'd0;
    localparam W_C = 3'd1;
    localparam T_C = 3'd2;
    localparam ABC_C = 3'd3;
    localparam EVAL = 3'd4;
    localparam MUX_SIG = 3'd5;
    
    // Variables internas
    
    // Variables maquina de estados
    reg [2:0] state = 3'd0;
    reg [2:0] state_next;
    
    // Trigger
    reg start_ant;
    
    // Contador para los ciclo for
    reg [5:0] cont;
    reg [5:0] cont_next;
    
    // Constante K
    wire [31:0] K [63:0];
    
    // W vector
    reg [31:0] W [63:0];
    reg [31:0] W_next [63:0];
    
    // Hash siguiente
    reg [255:0] H_next;
    
    // Logica para fin
    reg fin_next;
    
    // a,...,h , T1,T2
    reg [31:0] a,b,c,d,e,f,g,h,T1,T2; 
    reg [31:0] a_next,b_next,c_next,d_next,e_next,f_next,g_next,h_next,T1_next,T2_next; 
    
    // chip sigma chica 0 y 1
    reg [31:0] W_sig0_in;
    reg [31:0] W_sig1_in;
    reg [31:0] W_sig0_in_next;
    reg [31:0] W_sig1_in_next;
    
    
    wire [31:0] W_sig0_out;                       
    wire [31:0] W_sig1_out;
    
    // Variables para funciones internas
    
    // Maj
    wire [31:0] result_maj;
    
    // Sig0
    wire [31:0] result_sig0;
    
    // Sig1 
    wire [31:0] result_sig1;
    
    // Ch
    wire [31:0] result_ch;
    
    // Instancias de funciones 
    Sig_chi0 sig0(
        .X(W_sig0_in),
        .result(W_sig0_out)
    );
        
    Sig_chi1 sig1(
        .X(W_sig1_in),
        .result(W_sig1_out)
    );
            
    Maj Maj(    
        .X(a),          
        .Y(b),          
        .Z(c),          
        .result(result_maj) 
    );
                
    Sig0 Sig0(
        .X(a),
        .result(result_sig0) 
     );      
                
    Sig1 Sig1(
        .X(e),
        .result(result_sig1) 
    );    
                 
                 
    Ch Ch( 
         .X(e),
         .Y(f),
         .Z(g),
         .result(result_ch)
     );
     
// Assignaciones
    assign {K[0],K[1],K[2],K[3],K[4],K[5],K[6],K[7]} =
                {32'h428a2f98, 32'h71374491, 32'hb5c0fbcf, 32'he9b5dba5, 32'h3956c25b,32'h59f111f1, 32'h923f82a4 ,32'hab1c5ed5};
                
    assign {K[8],K[9],K[10],K[11],K[12],K[13],K[14],K[15]} =
                {32'hd807aa98, 32'h12835b01, 32'h243185be, 32'h550c7dc3, 32'h72be5d74,32'h80deb1fe, 32'h9bdc06a7 ,32'hc19bf174};
                
    assign {K[16],K[17],K[18],K[19],K[20],K[21],K[22],K[23]} =
                {32'he49b69c1, 32'hefbe4786, 32'h0fc19dc6, 32'h240ca1cc, 32'h2de92c6f,32'h4a7484aa, 32'h5cb0a9dc ,32'h76f988da};
                
    assign {K[24],K[25],K[26],K[27],K[28],K[29],K[30],K[31]} =
                {32'h983e5152, 32'ha831c66d, 32'hb00327c8, 32'hbf597fc7, 32'hc6e00bf3,32'hd5a79147, 32'h06ca6351 ,32'h14292967};
                
    assign {K[32],K[33],K[34],K[35],K[36],K[37],K[38],K[39]} =
                {32'h27b70a85, 32'h2e1b2138, 32'h4d2c6dfc, 32'h53380d13, 32'h650a7354,32'h766a0abb, 32'h81c2c92e ,32'h92722c85};
                
    assign {K[40],K[41],K[42],K[43],K[44],K[45],K[46],K[47]} =
                {32'ha2bfe8a1, 32'ha81a664b, 32'hc24b8b70, 32'hc76c51a3, 32'hd192e819,32'hd6990624, 32'hf40e3585 ,32'h106aa070};
                
    assign {K[48],K[49],K[50],K[51],K[52],K[53],K[54],K[55]} =
                {32'h19a4c116, 32'h1e376c08, 32'h2748774c, 32'h34b0bcb5, 32'h391c0cb3,32'h4ed8aa4a, 32'h5b9cca4f ,32'h682e6ff3};
                
    assign {K[56],K[57],K[58],K[59],K[60],K[61],K[62],K[63]} =
                {32'h748f82ee, 32'h78a5636f, 32'h84c87814, 32'h8cc70208, 32'h90befffa,32'ha4506ceb, 32'hbef9a3f7 ,32'hc67178f2};
 
    always @(*) begin
        W_sig0_in_next = W_sig0_in; // Multiplexado de entrada Sig_0 segun indice i(cont)
        W_sig1_in_next = W_sig1_in;        
       
        W_next = W;
        state_next = state;
        
        cont_next = cont;
                                                       
        {a_next,b_next,c_next,d_next,e_next,f_next,g_next,h_next,T1_next,T2_next} = {a,b,c,d,e,f,g,h,T1,T2};
        
        H_next = H;
        fin_next = fin;
        
        case (state)
            IDLE: begin 
                {W_next[0],W_next[1],W_next[2],W_next[3],W_next[4],W_next[5],
                W_next[6],W_next[7],W_next[8],W_next[9],W_next[10],W_next[11],
                W_next[12],W_next[13],W_next[14],W_next[15]} = M;
                
                {a_next,b_next,c_next,d_next,e_next,f_next,g_next,h_next} = H_ant;
                
                fin_next = 0;
                
                cont_next = 6'd0;
                if (start & ~start_ant) begin // Detector de cantos
                    state_next = T_C;
                    H_next = H_ant;
                end
            end
            
            W_C: begin // W[i] = sig0(W[i-15]) + sig1(W[i-2]) + W[i-16]
                case(cont)
                    6'd16:W_next[16] = W[0] + W[9]  + W_sig1_out + W_sig0_out; 
                    6'd17:W_next[17] = W[1] + W[10] + W_sig1_out + W_sig0_out; 
                    6'd18:W_next[18] = W[2] + W[11] + W_sig1_out + W_sig0_out; 
                    6'd19:W_next[19] = W[3] + W[12] + W_sig1_out + W_sig0_out; 
                    6'd20:W_next[20] = W[4] + W[13] + W_sig1_out + W_sig0_out; 
                    6'd21:W_next[21] = W[5] + W[14] + W_sig1_out + W_sig0_out; 
                    6'd22:W_next[22] = W[6] + W[15] + W_sig1_out + W_sig0_out; 
                    6'd23:W_next[23] = W[7] + W[16] + W_sig1_out + W_sig0_out; 
                    6'd24:W_next[24] = W[8] + W[17] + W_sig1_out + W_sig0_out; 
                    6'd25:W_next[25] = W[9] + W[18] + W_sig1_out + W_sig0_out; 
                    6'd26:W_next[26] = W[10] + W[19] + W_sig1_out + W_sig0_out; 
                    6'd27:W_next[27] = W[11] + W[20] + W_sig1_out + W_sig0_out; 
                    6'd28:W_next[28] = W[12] + W[21] + W_sig1_out + W_sig0_out; 
                    6'd29:W_next[29] = W[13] + W[22] + W_sig1_out + W_sig0_out; 
                    6'd30:W_next[30] = W[14] + W[23] + W_sig1_out + W_sig0_out; 
                    6'd31:W_next[31] = W[15] + W[24] + W_sig1_out + W_sig0_out; 
                    6'd32:W_next[32] = W[16] + W[25] + W_sig1_out + W_sig0_out; 
                    6'd33:W_next[33] = W[17] + W[26] + W_sig1_out + W_sig0_out; 
                    6'd34:W_next[34] = W[18] + W[27] + W_sig1_out + W_sig0_out; 
                    6'd35:W_next[35] = W[19] + W[28] + W_sig1_out + W_sig0_out; 
                    6'd36:W_next[36] = W[20] + W[29] + W_sig1_out + W_sig0_out; 
                    6'd37:W_next[37] = W[21] + W[30] + W_sig1_out + W_sig0_out; 
                    6'd38:W_next[38] = W[22] + W[31] + W_sig1_out + W_sig0_out; 
                    6'd39:W_next[39] = W[23] + W[32] + W_sig1_out + W_sig0_out; 
                    6'd40:W_next[40] = W[24] + W[33] + W_sig1_out + W_sig0_out; 
                    6'd41:W_next[41] = W[25] + W[34] + W_sig1_out + W_sig0_out; 
                    6'd42:W_next[42] = W[26] + W[35] + W_sig1_out + W_sig0_out; 
                    6'd43:W_next[43] = W[27] + W[36] + W_sig1_out + W_sig0_out; 
                    6'd44:W_next[44] = W[28] + W[37] + W_sig1_out + W_sig0_out; 
                    6'd45:W_next[45] = W[29] + W[38] + W_sig1_out + W_sig0_out; 
                    6'd46:W_next[46] = W[30] + W[39] + W_sig1_out + W_sig0_out; 
                    6'd47:W_next[47] = W[31] + W[40] + W_sig1_out + W_sig0_out; 
                    6'd48:W_next[48] = W[32] + W[41] + W_sig1_out + W_sig0_out; 
                    6'd49:W_next[49] = W[33] + W[42] + W_sig1_out + W_sig0_out; 
                    6'd50:W_next[50] = W[34] + W[43] + W_sig1_out + W_sig0_out; 
                    6'd51:W_next[51] = W[35] + W[44] + W_sig1_out + W_sig0_out; 
                    6'd52:W_next[52] = W[36] + W[45] + W_sig1_out + W_sig0_out; 
                    6'd53:W_next[53] = W[37] + W[46] + W_sig1_out + W_sig0_out; 
                    6'd54:W_next[54] = W[38] + W[47] + W_sig1_out + W_sig0_out; 
                    6'd55:W_next[55] = W[39] + W[48] + W_sig1_out + W_sig0_out; 
                    6'd56:W_next[56] = W[40] + W[49] + W_sig1_out + W_sig0_out; 
                    6'd57:W_next[57] = W[41] + W[50] + W_sig1_out + W_sig0_out; 
                    6'd58:W_next[58] = W[42] + W[51] + W_sig1_out + W_sig0_out; 
                    6'd59:W_next[59] = W[43] + W[52] + W_sig1_out + W_sig0_out; 
                    6'd60:W_next[60] = W[44] + W[53] + W_sig1_out + W_sig0_out; 
                    6'd61:W_next[61] = W[45] + W[54] + W_sig1_out + W_sig0_out; 
                    6'd62:W_next[62] = W[46] + W[55] + W_sig1_out + W_sig0_out; 
                    6'd63:W_next[63] = W[47] + W[56] + W_sig1_out + W_sig0_out; 
                    default: W_next = W;                                            
                endcase      
                state_next = T_C;
            end
            
            MUX_SIG:
            begin
                case(cont)
                    6'd16:begin W_sig1_in_next = W[14]; W_sig0_in_next = W[1]; end
                    6'd17:begin W_sig1_in_next = W[15]; W_sig0_in_next = W[2]; end
                    6'd18:begin W_sig1_in_next = W[16]; W_sig0_in_next = W[3]; end
                    6'd19:begin W_sig1_in_next = W[17]; W_sig0_in_next = W[4]; end
                    6'd20:begin W_sig1_in_next = W[18]; W_sig0_in_next = W[5]; end
                    6'd21:begin W_sig1_in_next = W[19]; W_sig0_in_next = W[6]; end
                    6'd22:begin W_sig1_in_next = W[20]; W_sig0_in_next = W[7]; end
                    6'd23:begin W_sig1_in_next = W[21]; W_sig0_in_next = W[8]; end
                    6'd24:begin W_sig1_in_next = W[22]; W_sig0_in_next = W[9]; end
                    6'd25:begin W_sig1_in_next = W[23]; W_sig0_in_next = W[10]; end
                    6'd26:begin W_sig1_in_next = W[24]; W_sig0_in_next = W[11]; end
                    6'd27:begin W_sig1_in_next = W[25]; W_sig0_in_next = W[12]; end
                    6'd28:begin W_sig1_in_next = W[26]; W_sig0_in_next = W[13]; end
                    6'd29:begin W_sig1_in_next = W[27]; W_sig0_in_next = W[14]; end
                    6'd30:begin W_sig1_in_next = W[28]; W_sig0_in_next = W[15]; end
                    6'd31:begin W_sig1_in_next = W[29]; W_sig0_in_next = W[16]; end
                    6'd32:begin W_sig1_in_next = W[30]; W_sig0_in_next = W[17]; end
                    6'd33:begin W_sig1_in_next = W[31]; W_sig0_in_next = W[18]; end
                    6'd34:begin W_sig1_in_next = W[32]; W_sig0_in_next = W[19]; end
                    6'd35:begin W_sig1_in_next = W[33]; W_sig0_in_next = W[20]; end
                    6'd36:begin W_sig1_in_next = W[34]; W_sig0_in_next = W[21]; end
                    6'd37:begin W_sig1_in_next = W[35]; W_sig0_in_next = W[22]; end
                    6'd38:begin W_sig1_in_next = W[36]; W_sig0_in_next = W[23]; end
                    6'd39:begin W_sig1_in_next = W[37]; W_sig0_in_next = W[24]; end
                    6'd40:begin W_sig1_in_next = W[38]; W_sig0_in_next = W[25]; end
                    6'd41:begin W_sig1_in_next = W[39]; W_sig0_in_next = W[26]; end
                    6'd42:begin W_sig1_in_next = W[40]; W_sig0_in_next = W[27]; end
                    6'd43:begin W_sig1_in_next = W[41]; W_sig0_in_next = W[28]; end
                    6'd44:begin W_sig1_in_next = W[42]; W_sig0_in_next = W[29]; end
                    6'd45:begin W_sig1_in_next = W[43]; W_sig0_in_next = W[30]; end
                    6'd46:begin W_sig1_in_next = W[44]; W_sig0_in_next = W[31]; end
                    6'd47:begin W_sig1_in_next = W[45]; W_sig0_in_next = W[32]; end
                    6'd48:begin W_sig1_in_next = W[46]; W_sig0_in_next = W[33]; end
                    6'd49:begin W_sig1_in_next = W[47]; W_sig0_in_next = W[34]; end
                    6'd50:begin W_sig1_in_next = W[48]; W_sig0_in_next = W[35]; end
                    6'd51:begin W_sig1_in_next = W[49]; W_sig0_in_next = W[36]; end
                    6'd52:begin W_sig1_in_next = W[50]; W_sig0_in_next = W[37]; end
                    6'd53:begin W_sig1_in_next = W[51]; W_sig0_in_next = W[38]; end
                    6'd54:begin W_sig1_in_next = W[52]; W_sig0_in_next = W[39]; end
                    6'd55:begin W_sig1_in_next = W[53]; W_sig0_in_next = W[40]; end
                    6'd56:begin W_sig1_in_next = W[54]; W_sig0_in_next = W[41]; end
                    6'd57:begin W_sig1_in_next = W[55]; W_sig0_in_next = W[42]; end
                    6'd58:begin W_sig1_in_next = W[56]; W_sig0_in_next = W[43]; end
                    6'd59:begin W_sig1_in_next = W[57]; W_sig0_in_next = W[44]; end
                    6'd60:begin W_sig1_in_next = W[58]; W_sig0_in_next = W[45]; end
                    6'd61:begin W_sig1_in_next = W[59]; W_sig0_in_next = W[46]; end
                    6'd62:begin W_sig1_in_next = W[60]; W_sig0_in_next = W[47]; end
                    6'd63:begin W_sig1_in_next = W[61]; W_sig0_in_next = W[48]; end
                    default:begin W_sig1_in_next = W[0]; W_sig0_in_next = W[0]; end                                               
                endcase
            state_next = W_C;
            end
            T_C: begin
                case(cont)
                    6'd0: T1_next = K[0] + W[0] + h + result_sig1 + result_ch;
                    6'd1: T1_next = K[1] + W[1] + h + result_sig1 + result_ch;
                    6'd2: T1_next = K[2] + W[2] + h + result_sig1 + result_ch;
                    6'd3: T1_next = K[3] + W[3] + h + result_sig1 + result_ch;
                    6'd4: T1_next = K[4] + W[4] + h + result_sig1 + result_ch;
                    6'd5: T1_next = K[5] + W[5] + h + result_sig1 + result_ch;
                    6'd6: T1_next = K[6] + W[6] + h + result_sig1 + result_ch;
                    6'd7: T1_next = K[7] + W[7] + h + result_sig1 + result_ch;
                    6'd8: T1_next = K[8] + W[8] + h + result_sig1 + result_ch;
                    6'd9: T1_next = K[9] + W[9] + h + result_sig1 + result_ch;
                    6'd10:T1_next = K[10] + W[10] + h + result_sig1 + result_ch;
                    6'd11:T1_next = K[11] + W[11] + h + result_sig1 + result_ch;
                    6'd12:T1_next = K[12] + W[12] + h + result_sig1 + result_ch;
                    6'd13:T1_next = K[13] + W[13] + h + result_sig1 + result_ch;
                    6'd14:T1_next = K[14] + W[14] + h + result_sig1 + result_ch;
                    6'd15:T1_next = K[15] + W[15] + h + result_sig1 + result_ch;
                    6'd16:T1_next = K[16] + W[16] + h + result_sig1 + result_ch;
                    6'd17:T1_next = K[17] + W[17] + h + result_sig1 + result_ch;
                    6'd18:T1_next = K[18] + W[18] + h + result_sig1 + result_ch;
                    6'd19:T1_next = K[19] + W[19] + h + result_sig1 + result_ch;
                    6'd20:T1_next = K[20] + W[20] + h + result_sig1 + result_ch;
                    6'd21:T1_next = K[21] + W[21] + h + result_sig1 + result_ch;
                    6'd22:T1_next = K[22] + W[22] + h + result_sig1 + result_ch;
                    6'd23:T1_next = K[23] + W[23] + h + result_sig1 + result_ch;
                    6'd24:T1_next = K[24] + W[24] + h + result_sig1 + result_ch;
                    6'd25:T1_next = K[25] + W[25] + h + result_sig1 + result_ch;
                    6'd26:T1_next = K[26] + W[26] + h + result_sig1 + result_ch;
                    6'd27:T1_next = K[27] + W[27] + h + result_sig1 + result_ch;
                    6'd28:T1_next = K[28] + W[28] + h + result_sig1 + result_ch;
                    6'd29:T1_next = K[29] + W[29] + h + result_sig1 + result_ch;
                    6'd30:T1_next = K[30] + W[30] + h + result_sig1 + result_ch;
                    6'd31:T1_next = K[31] + W[31] + h + result_sig1 + result_ch;
                    6'd32:T1_next = K[32] + W[32] + h + result_sig1 + result_ch;
                    6'd33:T1_next = K[33] + W[33] + h + result_sig1 + result_ch;
                    6'd34:T1_next = K[34] + W[34] + h + result_sig1 + result_ch;
                    6'd35:T1_next = K[35] + W[35] + h + result_sig1 + result_ch;
                    6'd36:T1_next = K[36] + W[36] + h + result_sig1 + result_ch;
                    6'd37:T1_next = K[37] + W[37] + h + result_sig1 + result_ch;
                    6'd38:T1_next = K[38] + W[38] + h + result_sig1 + result_ch;
                    6'd39:T1_next = K[39] + W[39] + h + result_sig1 + result_ch;
                    6'd40:T1_next = K[40] + W[40] + h + result_sig1 + result_ch;
                    6'd41:T1_next = K[41] + W[41] + h + result_sig1 + result_ch;
                    6'd42:T1_next = K[42] + W[42] + h + result_sig1 + result_ch;
                    6'd43:T1_next = K[43] + W[43] + h + result_sig1 + result_ch;
                    6'd44:T1_next = K[44] + W[44] + h + result_sig1 + result_ch;
                    6'd45:T1_next = K[45] + W[45] + h + result_sig1 + result_ch;
                    6'd46:T1_next = K[46] + W[46] + h + result_sig1 + result_ch;
                    6'd47:T1_next = K[47] + W[47] + h + result_sig1 + result_ch;
                    6'd48:T1_next = K[48] + W[48] + h + result_sig1 + result_ch;
                    6'd49:T1_next = K[49] + W[49] + h + result_sig1 + result_ch;
                    6'd50:T1_next = K[50] + W[50] + h + result_sig1 + result_ch;
                    6'd51:T1_next = K[51] + W[51] + h + result_sig1 + result_ch;
                    6'd52:T1_next = K[52] + W[52] + h + result_sig1 + result_ch;
                    6'd53:T1_next = K[53] + W[53] + h + result_sig1 + result_ch;
                    6'd54:T1_next = K[54] + W[54] + h + result_sig1 + result_ch;
                    6'd55:T1_next = K[55] + W[55] + h + result_sig1 + result_ch;
                    6'd56:T1_next = K[56] + W[56] + h + result_sig1 + result_ch;
                    6'd57:T1_next = K[57] + W[57] + h + result_sig1 + result_ch;
                    6'd58:T1_next = K[58] + W[58] + h + result_sig1 + result_ch;
                    6'd59:T1_next = K[59] + W[59] + h + result_sig1 + result_ch;
                    6'd60:T1_next = K[60] + W[60] + h + result_sig1 + result_ch;
                    6'd61:T1_next = K[61] + W[61] + h + result_sig1 + result_ch;
                    6'd62:T1_next = K[62] + W[62] + h + result_sig1 + result_ch;
                    6'd63:T1_next = K[63] + W[63] + h + result_sig1 + result_ch;
                    default: T1_next = T1;                   
                endcase
               
                T2_next = result_sig0 + result_maj;
                state_next = ABC_C;
            
            end
            
            ABC_C: // Modifica las variables, se requiere T1 y T2 ya previamente calculados
            begin
                h_next = g;
                g_next = f;
                f_next = e;
                e_next = d + T1;
                d_next = c;
                c_next = b;
                b_next = a;
                a_next = T1 + T2; 
                state_next = EVAL;
                
            end
            EVAL: begin // Este estado evalua si se hicieron 64 ciclos, caso contrario vuelve a trabajar segun el cont 
                cont_next = cont + 6'd1;
                if(cont == 6'd63) begin // Fin ciclo de 64 veces
                    // Evalua nuevo Hash y levanta bandera de finalizacion
                    H_next[255:224] = H_ant[255:224] + a;
                    H_next[223:192] = H_ant[223:192] + b;
                    H_next[191:160] = H_ant[191:160] + c;
                    H_next[159:128] = H_ant[159:128] + d;
                    H_next[127:96] = H_ant[127:96] + e;
                    H_next[95:64] = H_ant[95:64] + f;
                    H_next[63:32] = H_ant[63:32] + g;
                    H_next[31:0] = H_ant[31:0] + h;
                    state_next = IDLE;
                    fin_next = 1'b1;
                end
                else begin
                    if(cont < 15) state_next = T_C;  // Se empieza a modificar el registro W, cuando cont >= 16
                    else state_next = MUX_SIG;    
                end
            end
            default: state_next = IDLE;
        endcase
     end
    
    integer i,j;

    always @(posedge clk) begin
        start_ant <= start; // Valor pasado de start
        if (rst[0]) begin
            h <= 32'd0;
            g <= 32'd0;
            f <= 32'd0;
            e <= 32'd0;
            d <= 32'd0;
        end
        else begin
            h <= h_next;                                    
            g <= g_next;                                    
            f <= f_next;                                    
            e <= e_next;                                    
            d <= d_next;  
        end
        
        if (rst[1]) begin
            c <= 32'd0;
            b <= 32'd0;
            a <= 32'd0;
            T1 <= 32'd0;
            T2 <= 32'd0;
        end
        else begin
            c <= c_next;                                    
            b <= b_next;                                    
            a <= a_next;                                    
            T1 <= T1_next;                                   
            T2 <= T2_next;                 
        end
        
        if (rst[2]) begin
            cont <= 6'd0;
            state <= IDLE;
            
            W_sig0_in <= 32'd0;
            W_sig1_in <= 32'd0;
            
            fin <=  1'b0;
        end
        else begin
            cont <= cont_next;                             
            state <= state_next;
            
            W_sig0_in <= W_sig0_in_next;
            W_sig1_in <= W_sig1_in_next;
            
            fin <= fin_next; 
        end
        
        if (rst[3]) begin
            H <= 256'd0; 
        end
        else begin
            H <= H_next;  // por default H(t) <= H(t-1)
        end
        for (j = 4; j < 12; j++) begin
            if (rst[j]) begin
                for (i = 8*(j-4); i <= 8*(j-4) + 7; i++) W[i] <= 32'd0;
            end
            else begin
                for (i = 8*(j-4); i <= 8*(j-4) + 7; i++) W[i] <= W_next[i];
            end
        end 
        
        
    end

endmodule

/*
        if (rst[4]) begin
            for (i = 1; i < 64; i++) W[i] <= 32'd0;
        end
        else begin
            W <= W_next;
        end
*/