`timescale 1ns / 1ps


module Padding(clk, rst, new_M, data_ready, n, N, length, k, data, M, ok, new_data);
    
    // Parametros
    parameter N_length = 10;
    parameter N_N = 2;
    parameter N_MAX = 3;
    parameter MAX = 1023;
   
    // Entradas
    input clk;
    input [1:0] rst;
    input new_M;              //flag que indica pedido de M (se mantiene en alto hasta que llegue un ok de M)
    input data_ready;        // falg que indica que el dato esta listo
    input [N_N-1:0] n;       // señal que indica el n actual para M
    input [N_N-1:0] N;       // señal que indica N total
    input [N_length-1:0] length; //largo de string
    input [8:0] k;              // cantidad de zeros de 0 a 511 
    input [511:0] data;         // datos leidos obtenido de modulo manger ram // diseñado para 512 bits
    
    // Salidas  
    output reg [511:0] M; // hacia Hash_i
    output reg ok;        // bandera de que M esta listo
    output reg new_data;     // pulso q pide el siguiente dato
    
    // Estados
    localparam DATA = 3'd1;   // escribir data en M
    localparam ONE  = 3'd2;   // escribir un 1 en M
    localparam LENGTH = 3'd3; // escribir el largo en M
    localparam ZERO = 3'd0;   // escribir zeros en M
    localparam IDLE = 3'd4;  // inactividad 
    localparam WAIT_CALLED = 3'd5; // esperar un pedido de un nuevo M
    localparam WAIT_DATA = 3'd6;  // esperar el dato desde la ram
    
    // Variables Internas
    
    // Variables Maquina de estados
    reg [2:0] state; //estado de la maquina
    reg [2:0] state_next; // estado siguiente de la maquina
    reg [2:0] state_return; // variable que guarda el estado que se necesita para volver
    reg [2:0] state_return_next;
     
    reg new_M_ant;  // Detector de cantos banderas
   
    // Flip flop salida
    reg [511:0] M_next;
    reg ok_next;
    reg new_data_next;
    
    // Combinacional
    integer i, L;
    
    always @(*) begin
        state_next = state;
        state_return_next = state_return;

        M_next = M;
        ok_next = 1'b0;

        new_data_next = 1'b0;  // por default no pide siguiente dato
        L = length;

        case (state)
            IDLE: begin     // Espera hasta que llega un pedido
                if(new_M & ~new_M_ant) begin
                    new_data_next = 1'b1;
                    state_next = WAIT_DATA;
                    ok_next = 1'd0;
                    state_return_next = DATA;
                end
            end
            WAIT_CALLED: begin
                if (new_M & ~new_M_ant)
                    state_next = state_return;
            end
            WAIT_DATA: begin  // Espera que lleguen los datos. El criterio para saber cuando llega un dato, es cuando se levanta una bandera que viene desde afuera
                new_data_next = 1'b1;
                if (data_ready) begin
                     if (new_M)
                        state_next = DATA; // Cambia de estado si se levanta la bandera externa
                     else
                        state_next = WAIT_CALLED; // En caso contrario, continua esperando la bandera externa
                     new_data_next = 1'b0;
                end
            end
            DATA: begin
                    M_next = data; // Data completo es asignado, incluso datos que no sirven (porque el largo especificado indica eso)
                for (i = 0; i < MAX/512 + 1; i++) begin
                    if (length < 512)
                        state_next = ONE;
                    else if ((length == 512*i) && (n == i)) begin
                        state_next = WAIT_CALLED;
                        state_return_next = ONE;
                        ok_next = 1'b1;
                    end
                    else if ((length > 512*i ) && (n == i)) begin
                        state_next = WAIT_DATA;
                        state_return_next = DATA;
                        new_data_next = 1'b1;
                        ok_next = 1'b1;
                    end
                    else state_next = ONE;
                end
            end
            ONE: begin
                for(i = 0; i < MAX/512 + 1; i++) begin
                    if ((length < (i + 1)*512 ) && (length >= i*512)) begin
                        M_next[511 - L + i*512] = 1'b1;
                        if (length + 1 == (i + 1)*512) begin 
                            ok_next = 1'b1;
                            state_next = WAIT_CALLED;
                            state_return_next = ZERO;
                        end
                        else
                            state_next = ZERO;
                    end
                 end
            end
            ZERO: begin     // Se agregan ceros solo en el ultimo y penultimo bloque
                if (n == N) begin // k e [0,447]
                    // no encontre una forma de escribirlo bonito
                    case(k)
                        9'd0:  M_next = M; // se mantiene igual.
                        9'd1:  M_next[64] = 0;
                        9'd2:  M_next[65:64] = 0;
                        9'd3:  M_next[66:64] = 0;
                        9'd4:  M_next[67:64] = 0;
                        9'd5:  M_next[68:64] = 0;
                        9'd6:  M_next[69:64] = 0;
                        9'd7:  M_next[70:64] = 0;
                        9'd8:  M_next[71:64] = 0;
                        9'd9:  M_next[72:64] = 0;
                        9'd10: M_next[73:64] = 0;
                        9'd11: M_next[74:64] = 0;
                        9'd12: M_next[75:64] = 0;
                        9'd13: M_next[76:64] = 0;
                        9'd14: M_next[77:64] = 0;
                        9'd15: M_next[78:64] = 0;
                        9'd16: M_next[79:64] = 0;
                        9'd17: M_next[80:64] = 0;
                        9'd18: M_next[81:64] = 0;
                        9'd19: M_next[82:64] = 0;
                        9'd20: M_next[83:64] = 0; 
                        9'd21: M_next[84:64] = 0;
                        9'd22: M_next[85:64] = 0;
                        9'd23: M_next[86:64] = 0;
                        9'd24: M_next[87:64] = 0;
                        9'd25: M_next[88:64] = 0;
                        9'd26: M_next[89:64] = 0;
                        9'd27: M_next[90:64] = 0;
                        9'd28: M_next[91:64] = 0;
                        9'd29: M_next[92:64] = 0;
                        9'd30: M_next[93:64] = 0; 
                        9'd31: M_next[94:64] = 0;
                        9'd32: M_next[95:64] = 0;
                        9'd33: M_next[96:64] = 0;
                        9'd34: M_next[97:64] = 0;
                        9'd35: M_next[98:64] = 0;
                        9'd36: M_next[99:64] = 0;
                        9'd37: M_next[100:64] = 0;
                        9'd38: M_next[101:64] = 0;
                        9'd39: M_next[102:64] = 0;
                        9'd40: M_next[103:64] = 0; 
                        9'd41: M_next[104:64] = 0;
                        9'd42: M_next[105:64] = 0;
                        9'd43: M_next[106:64] = 0;
                        9'd44: M_next[107:64] = 0;
                        9'd45: M_next[108:64] = 0;
                        9'd46: M_next[109:64] = 0;
                        9'd47: M_next[110:64] = 0;
                        9'd48: M_next[111:64] = 0;
                        9'd49: M_next[112:64] = 0;
                        9'd50: M_next[113:64] = 0; 
                        9'd51: M_next[114:64] = 0;
                        9'd52: M_next[115:64] = 0;
                        9'd53: M_next[116:64] = 0;
                        9'd54: M_next[117:64] = 0;
                        9'd55: M_next[118:64] = 0;
                        9'd56: M_next[119:64] = 0;
                        9'd57: M_next[120:64] = 0;
                        9'd58: M_next[121:64] = 0;
                        9'd59: M_next[122:64] = 0;
                        9'd60: M_next[123:64] = 0; 
                        9'd61: M_next[124:64] = 0;
                        9'd62: M_next[125:64] = 0;
                        9'd63: M_next[126:64] = 0;
                        9'd64: M_next[127:64] = 0;
                        9'd65: M_next[128:64] = 0;
                        9'd66: M_next[129:64] = 0;
                        9'd67: M_next[130:64] = 0;
                        9'd68: M_next[131:64] = 0;
                        9'd69: M_next[132:64] = 0;
                        9'd70: M_next[133:64] = 0; 
                        9'd71: M_next[134:64] = 0;
                        9'd72: M_next[135:64] = 0;
                        9'd73: M_next[136:64] = 0;
                        9'd74: M_next[137:64] = 0;
                        9'd75: M_next[138:64] = 0;
                        9'd76: M_next[139:64] = 0;
                        9'd77: M_next[140:64] = 0;
                        9'd78: M_next[141:64] = 0;
                        9'd79: M_next[142:64] = 0;
                        9'd80: M_next[143:64] = 0; 
                        9'd81: M_next[144:64] = 0;
                        9'd82: M_next[145:64] = 0;
                        9'd83: M_next[146:64] = 0;
                        9'd84: M_next[147:64] = 0;
                        9'd85: M_next[148:64] = 0;
                        9'd86: M_next[149:64] = 0;
                        9'd87: M_next[150:64] = 0;
                        9'd88: M_next[151:64] = 0;
                        9'd89: M_next[152:64] = 0;
                        9'd90: M_next[153:64] = 0; 
                        9'd91: M_next[154:64] = 0;
                        9'd92: M_next[155:64] = 0;
                        9'd93: M_next[156:64] = 0;
                        9'd94: M_next[157:64] = 0;
                        9'd95: M_next[158:64] = 0;
                        9'd96: M_next[159:64] = 0;
                        9'd97: M_next[160:64] = 0;
                        9'd98: M_next[161:64] = 0;
                        9'd99: M_next[162:64] = 0;
                        9'd100: M_next[163:64] = 0;
                        9'd101: M_next[164:64] = 0;
                        9'd102: M_next[165:64] = 0;
                        9'd103: M_next[166:64] = 0;
                        9'd104: M_next[167:64] = 0;
                        9'd105: M_next[168:64] = 0;
                        9'd106: M_next[169:64] = 0;
                        9'd107: M_next[170:64] = 0;
                        9'd108: M_next[171:64] = 0;
                        9'd109: M_next[172:64] = 0;
                        9'd110: M_next[173:64] = 0;
                        9'd111: M_next[174:64] = 0;
                        9'd112: M_next[175:64] = 0;
                        9'd113: M_next[176:64] = 0;
                        9'd114: M_next[177:64] = 0;
                        9'd115: M_next[178:64] = 0;
                        9'd116: M_next[179:64] = 0;
                        9'd117: M_next[180:64] = 0;
                        9'd118: M_next[181:64] = 0;
                        9'd119: M_next[182:64] = 0;
                        9'd120: M_next[183:64] = 0; 
                        9'd121: M_next[184:64] = 0;
                        9'd122: M_next[185:64] = 0;
                        9'd123: M_next[186:64] = 0;
                        9'd124: M_next[187:64] = 0;
                        9'd125: M_next[188:64] = 0;
                        9'd126: M_next[189:64] = 0;
                        9'd127: M_next[190:64] = 0;
                        9'd128: M_next[191:64] = 0;
                        9'd129: M_next[192:64] = 0;
                        9'd130: M_next[193:64] = 0; 
                        9'd131: M_next[194:64] = 0;
                        9'd132: M_next[195:64] = 0;
                        9'd133: M_next[196:64] = 0;
                        9'd134: M_next[197:64] = 0;
                        9'd135: M_next[198:64] = 0;
                        9'd136: M_next[199:64] = 0;
                        9'd137: M_next[200:64] = 0;
                        9'd138: M_next[201:64] = 0;
                        9'd139: M_next[202:64] = 0;
                        9'd140: M_next[203:64] = 0; 
                        9'd141: M_next[204:64] = 0;
                        9'd142: M_next[205:64] = 0;
                        9'd143: M_next[206:64] = 0;
                        9'd144: M_next[207:64] = 0;
                        9'd145: M_next[208:64] = 0;
                        9'd146: M_next[209:64] = 0;
                        9'd147: M_next[210:64] = 0;
                        9'd148: M_next[211:64] = 0;
                        9'd149: M_next[212:64] = 0;
                        9'd150: M_next[213:64] = 0; 
                        9'd151: M_next[214:64] = 0;
                        9'd152: M_next[215:64] = 0;
                        9'd153: M_next[216:64] = 0;
                        9'd154: M_next[217:64] = 0;
                        9'd155: M_next[218:64] = 0;
                        9'd156: M_next[219:64] = 0;
                        9'd157: M_next[220:64] = 0;
                        9'd158: M_next[221:64] = 0;
                        9'd159: M_next[222:64] = 0;
                        9'd160: M_next[223:64] = 0; 
                        9'd161: M_next[224:64] = 0;
                        9'd162: M_next[225:64] = 0;
                        9'd163: M_next[226:64] = 0;
                        9'd164: M_next[227:64] = 0;
                        9'd165: M_next[228:64] = 0;
                        9'd166: M_next[229:64] = 0;
                        9'd167: M_next[230:64] = 0;
                        9'd168: M_next[231:64] = 0;
                        9'd169: M_next[232:64] = 0;
                        9'd170: M_next[233:64] = 0; 
                        9'd171: M_next[234:64] = 0;
                        9'd172: M_next[235:64] = 0;
                        9'd173: M_next[236:64] = 0;
                        9'd174: M_next[237:64] = 0;
                        9'd175: M_next[238:64] = 0;
                        9'd176: M_next[239:64] = 0;
                        9'd177: M_next[240:64] = 0;
                        9'd178: M_next[241:64] = 0;
                        9'd179: M_next[242:64] = 0;
                        9'd180: M_next[243:64] = 0; 
                        9'd181: M_next[244:64] = 0;
                        9'd182: M_next[245:64] = 0;
                        9'd183: M_next[246:64] = 0;
                        9'd184: M_next[247:64] = 0;
                        9'd185: M_next[248:64] = 0;
                        9'd186: M_next[249:64] = 0;
                        9'd187: M_next[250:64] = 0;
                        9'd188: M_next[251:64] = 0;
                        9'd189: M_next[252:64] = 0;
                        9'd190: M_next[253:64] = 0; 
                        9'd191: M_next[254:64] = 0;
                        9'd192: M_next[255:64] = 0;
                        9'd193: M_next[256:64] = 0;
                        9'd194: M_next[257:64] = 0;
                        9'd195: M_next[258:64] = 0;
                        9'd196: M_next[259:64] = 0;
                        9'd197: M_next[260:64] = 0;
                        9'd198: M_next[261:64] = 0;
                        9'd199: M_next[262:64] = 0;
                        9'd200: M_next[263:64] = 0;
                        9'd201: M_next[264:64] = 0;
                        9'd202: M_next[265:64] = 0;
                        9'd203: M_next[266:64] = 0;
                        9'd204: M_next[267:64] = 0;
                        9'd205: M_next[268:64] = 0;
                        9'd206: M_next[269:64] = 0;
                        9'd207: M_next[270:64] = 0;
                        9'd208: M_next[271:64] = 0;
                        9'd209: M_next[272:64] = 0;
                        9'd210: M_next[273:64] = 0;
                        9'd211: M_next[274:64] = 0;
                        9'd212: M_next[275:64] = 0;
                        9'd213: M_next[276:64] = 0;
                        9'd214: M_next[277:64] = 0;
                        9'd215: M_next[278:64] = 0;
                        9'd216: M_next[279:64] = 0;
                        9'd217: M_next[280:64] = 0;
                        9'd218: M_next[281:64] = 0;
                        9'd219: M_next[282:64] = 0;
                        9'd220: M_next[283:64] = 0; 
                        9'd221: M_next[284:64] = 0;
                        9'd222: M_next[285:64] = 0;
                        9'd223: M_next[286:64] = 0;
                        9'd224: M_next[287:64] = 0;
                        9'd225: M_next[288:64] = 0;
                        9'd226: M_next[289:64] = 0;
                        9'd227: M_next[290:64] = 0;
                        9'd228: M_next[291:64] = 0;
                        9'd229: M_next[292:64] = 0;
                        9'd230: M_next[293:64] = 0; 
                        9'd231: M_next[294:64] = 0;
                        9'd232: M_next[295:64] = 0;
                        9'd233: M_next[296:64] = 0;
                        9'd234: M_next[297:64] = 0;
                        9'd235: M_next[298:64] = 0;
                        9'd236: M_next[299:64] = 0;
                        9'd237: M_next[300:64] = 0;
                        9'd238: M_next[301:64] = 0;
                        9'd239: M_next[302:64] = 0;
                        9'd240: M_next[303:64] = 0; 
                        9'd241: M_next[304:64] = 0;
                        9'd242: M_next[305:64] = 0;
                        9'd243: M_next[306:64] = 0;
                        9'd244: M_next[307:64] = 0;
                        9'd245: M_next[308:64] = 0;
                        9'd246: M_next[309:64] = 0;
                        9'd247: M_next[310:64] = 0;
                        9'd248: M_next[311:64] = 0;
                        9'd249: M_next[312:64] = 0;
                        9'd250: M_next[313:64] = 0; 
                        9'd251: M_next[314:64] = 0;
                        9'd252: M_next[315:64] = 0;
                        9'd253: M_next[316:64] = 0;
                        9'd254: M_next[317:64] = 0;
                        9'd255: M_next[318:64] = 0;
                        9'd256: M_next[319:64] = 0;
                        9'd257: M_next[320:64] = 0;
                        9'd258: M_next[321:64] = 0;
                        9'd259: M_next[322:64] = 0;
                        9'd260: M_next[323:64] = 0; 
                        9'd261: M_next[324:64] = 0;
                        9'd262: M_next[325:64] = 0;
                        9'd263: M_next[326:64] = 0;
                        9'd264: M_next[327:64] = 0;
                        9'd265: M_next[328:64] = 0;
                        9'd266: M_next[329:64] = 0;
                        9'd267: M_next[330:64] = 0;
                        9'd268: M_next[331:64] = 0;
                        9'd269: M_next[332:64] = 0;
                        9'd270: M_next[333:64] = 0; 
                        9'd271: M_next[334:64] = 0;
                        9'd272: M_next[335:64] = 0;
                        9'd273: M_next[336:64] = 0;
                        9'd274: M_next[337:64] = 0;
                        9'd275: M_next[338:64] = 0;
                        9'd276: M_next[339:64] = 0;
                        9'd277: M_next[340:64] = 0;
                        9'd278: M_next[341:64] = 0;
                        9'd279: M_next[342:64] = 0;
                        9'd280: M_next[343:64] = 0; 
                        9'd281: M_next[344:64] = 0;
                        9'd282: M_next[345:64] = 0;
                        9'd283: M_next[346:64] = 0;
                        9'd284: M_next[347:64] = 0;
                        9'd285: M_next[348:64] = 0;
                        9'd286: M_next[349:64] = 0;
                        9'd287: M_next[350:64] = 0;
                        9'd288: M_next[351:64] = 0;
                        9'd289: M_next[352:64] = 0;
                        9'd290: M_next[353:64] = 0; 
                        9'd291: M_next[354:64] = 0;
                        9'd292: M_next[355:64] = 0;
                        9'd293: M_next[356:64] = 0;
                        9'd294: M_next[357:64] = 0;
                        9'd295: M_next[358:64] = 0;
                        9'd296: M_next[359:64] = 0;
                        9'd297: M_next[360:64] = 0;
                        9'd298: M_next[361:64] = 0;
                        9'd299: M_next[362:64] = 0;
                        9'd300: M_next[363:64] = 0;
                        9'd301: M_next[364:64] = 0;
                        9'd302: M_next[365:64] = 0;
                        9'd303: M_next[366:64] = 0;
                        9'd304: M_next[367:64] = 0;
                        9'd305: M_next[368:64] = 0;
                        9'd306: M_next[369:64] = 0;
                        9'd307: M_next[370:64] = 0;
                        9'd308: M_next[371:64] = 0;
                        9'd309: M_next[372:64] = 0;
                        9'd310: M_next[373:64] = 0;
                        9'd311: M_next[374:64] = 0;
                        9'd312: M_next[375:64] = 0;
                        9'd313: M_next[376:64] = 0;
                        9'd314: M_next[377:64] = 0;
                        9'd315: M_next[378:64] = 0;
                        9'd316: M_next[379:64] = 0;
                        9'd317: M_next[380:64] = 0;
                        9'd318: M_next[381:64] = 0;
                        9'd319: M_next[382:64] = 0;
                        9'd320: M_next[383:64] = 0; 
                        9'd321: M_next[384:64] = 0;
                        9'd322: M_next[385:64] = 0;
                        9'd323: M_next[386:64] = 0;
                        9'd324: M_next[387:64] = 0;
                        9'd325: M_next[388:64] = 0;
                        9'd326: M_next[389:64] = 0;
                        9'd327: M_next[390:64] = 0;
                        9'd328: M_next[391:64] = 0;
                        9'd329: M_next[392:64] = 0;
                        9'd330: M_next[393:64] = 0; 
                        9'd331: M_next[394:64] = 0;
                        9'd332: M_next[395:64] = 0;
                        9'd333: M_next[396:64] = 0;
                        9'd334: M_next[397:64] = 0;
                        9'd335: M_next[398:64] = 0;
                        9'd336: M_next[399:64] = 0;
                        9'd337: M_next[400:64] = 0;
                        9'd338: M_next[401:64] = 0;
                        9'd339: M_next[402:64] = 0;
                        9'd340: M_next[403:64] = 0; 
                        9'd341: M_next[404:64] = 0;
                        9'd342: M_next[405:64] = 0;
                        9'd343: M_next[406:64] = 0;
                        9'd344: M_next[407:64] = 0;
                        9'd345: M_next[408:64] = 0;
                        9'd346: M_next[409:64] = 0;
                        9'd347: M_next[410:64] = 0;
                        9'd348: M_next[411:64] = 0;
                        9'd349: M_next[412:64] = 0;
                        9'd350: M_next[413:64] = 0; 
                        9'd351: M_next[414:64] = 0;
                        9'd352: M_next[415:64] = 0;
                        9'd353: M_next[416:64] = 0;
                        9'd354: M_next[417:64] = 0;
                        9'd355: M_next[418:64] = 0;
                        9'd356: M_next[419:64] = 0;
                        9'd357: M_next[420:64] = 0;
                        9'd358: M_next[421:64] = 0;
                        9'd359: M_next[422:64] = 0;
                        9'd360: M_next[423:64] = 0; 
                        9'd361: M_next[424:64] = 0;
                        9'd362: M_next[425:64] = 0;
                        9'd363: M_next[426:64] = 0;
                        9'd364: M_next[427:64] = 0;
                        9'd365: M_next[428:64] = 0;
                        9'd366: M_next[429:64] = 0;
                        9'd367: M_next[430:64] = 0;
                        9'd368: M_next[431:64] = 0;
                        9'd369: M_next[432:64] = 0;
                        9'd370: M_next[433:64] = 0; 
                        9'd371: M_next[434:64] = 0;
                        9'd372: M_next[435:64] = 0;
                        9'd373: M_next[436:64] = 0;
                        9'd374: M_next[437:64] = 0;
                        9'd375: M_next[438:64] = 0;
                        9'd376: M_next[439:64] = 0;
                        9'd377: M_next[440:64] = 0;
                        9'd378: M_next[441:64] = 0;
                        9'd379: M_next[442:64] = 0;
                        9'd380: M_next[443:64] = 0; 
                        9'd381: M_next[444:64] = 0;
                        9'd382: M_next[445:64] = 0;
                        9'd383: M_next[446:64] = 0;
                        9'd384: M_next[447:64] = 0;
                        9'd385: M_next[448:64] = 0;
                        9'd386: M_next[449:64] = 0;
                        9'd387: M_next[450:64] = 0;
                        9'd388: M_next[451:64] = 0;
                        9'd389: M_next[452:64] = 0;
                        9'd390: M_next[453:64] = 0; 
                        9'd391: M_next[454:64] = 0;
                        9'd392: M_next[455:64] = 0;
                        9'd393: M_next[456:64] = 0;
                        9'd394: M_next[457:64] = 0;
                        9'd395: M_next[458:64] = 0;
                        9'd396: M_next[459:64] = 0;
                        9'd397: M_next[460:64] = 0;
                        9'd398: M_next[461:64] = 0;
                        9'd399: M_next[462:64] = 0;
                        9'd400: M_next[463:64] = 0;
                        9'd401: M_next[464:64] = 0;
                        9'd402: M_next[465:64] = 0;
                        9'd403: M_next[466:64] = 0;
                        9'd404: M_next[467:64] = 0;
                        9'd405: M_next[468:64] = 0;
                        9'd406: M_next[469:64] = 0;
                        9'd407: M_next[470:64] = 0;
                        9'd408: M_next[471:64] = 0;
                        9'd409: M_next[472:64] = 0;
                        9'd410: M_next[473:64] = 0;
                        9'd411: M_next[474:64] = 0;
                        9'd412: M_next[475:64] = 0;
                        9'd413: M_next[476:64] = 0;
                        9'd414: M_next[477:64] = 0;
                        9'd415: M_next[478:64] = 0;
                        9'd416: M_next[479:64] = 0;
                        9'd417: M_next[480:64] = 0;
                        9'd418: M_next[481:64] = 0;
                        9'd419: M_next[482:64] = 0;
                        9'd420: M_next[483:64] = 0; 
                        9'd421: M_next[484:64] = 0;
                        9'd422: M_next[485:64] = 0;
                        9'd423: M_next[486:64] = 0;
                        9'd424: M_next[487:64] = 0;
                        9'd425: M_next[488:64] = 0;
                        9'd426: M_next[489:64] = 0;
                        9'd427: M_next[490:64] = 0;
                        9'd428: M_next[491:64] = 0;
                        9'd429: M_next[492:64] = 0;
                        9'd430: M_next[493:64] = 0; 
                        9'd431: M_next[494:64] = 0;
                        9'd432: M_next[495:64] = 0;
                        9'd433: M_next[496:64] = 0;
                        9'd434: M_next[497:64] = 0;
                        9'd435: M_next[498:64] = 0;
                        9'd436: M_next[499:64] = 0;
                        9'd437: M_next[500:64] = 0;
                        9'd438: M_next[501:64] = 0;
                        9'd439: M_next[502:64] = 0;
                        9'd440: M_next[503:64] = 0; 
                        9'd441: M_next[504:64] = 0;
                        9'd442: M_next[505:64] = 0;
                        9'd443: M_next[506:64] = 0;
                        9'd444: M_next[507:64] = 0;
                        9'd445: M_next[508:64] = 0;
                        9'd446: M_next[509:64] = 0;
                        9'd447: M_next[510:64] = 0;
                        default: M_next[511:64] = 0; //k -> 448 a 511 
                    endcase
                                 
                    state_next = LENGTH;
                end
                
                else if(n < N) begin // k e [448 , 511]
                    case(k)
                        9'd448 : M_next = M;
                        9'd449 : M_next[0] = 0;
                        9'd450 : M_next[1:0] = 0;
                        9'd451 : M_next[2:0] = 0;
                        9'd452 : M_next[3:0] = 0;
                        9'd453 : M_next[4:0] = 0;
                        9'd454 : M_next[5:0] = 0;
                        9'd455 : M_next[6:0] = 0;
                        9'd456 : M_next[7:0] = 0;
                        9'd457 : M_next[8:0] = 0;
                        9'd458 : M_next[9:0] = 0;
                        9'd459 : M_next[10:0] = 0;
                        9'd460 : M_next[11:0] = 0;
                        9'd461 : M_next[12:0] = 0;
                        9'd462 : M_next[13:0] = 0;
                        9'd463 : M_next[14:0] = 0;
                        9'd464 : M_next[15:0] = 0;
                        9'd465 : M_next[16:0] = 0;
                        9'd466 : M_next[17:0] = 0;
                        9'd467 : M_next[18:0] = 0;
                        9'd468 : M_next[19:0] = 0;
                        9'd469 : M_next[20:0] = 0;
                        9'd470 : M_next[21:0] = 0;
                        9'd471 : M_next[22:0] = 0;
                        9'd472 : M_next[23:0] = 0;
                        9'd473 : M_next[24:0] = 0;
                        9'd474 : M_next[25:0] = 0;
                        9'd475 : M_next[26:0] = 0;
                        9'd476 : M_next[27:0] = 0;
                        9'd477 : M_next[28:0] = 0;
                        9'd478 : M_next[29:0] = 0;
                        9'd479 : M_next[30:0] = 0;
                        9'd480 : M_next[31:0] = 0;
                        9'd481 : M_next[32:0] = 0;
                        9'd482 : M_next[33:0] = 0;
                        9'd483 : M_next[34:0] = 0;
                        9'd484 : M_next[35:0] = 0;
                        9'd485 : M_next[36:0] = 0;
                        9'd486 : M_next[37:0] = 0;
                        9'd487 : M_next[38:0] = 0;
                        9'd488 : M_next[39:0] = 0;
                        9'd489 : M_next[40:0] = 0;
                        9'd490 : M_next[41:0] = 0;
                        9'd491 : M_next[42:0] = 0;
                        9'd492 : M_next[43:0] = 0;
                        9'd493 : M_next[44:0] = 0;
                        9'd494 : M_next[45:0] = 0;
                        9'd495 : M_next[46:0] = 0;
                        9'd496 : M_next[47:0] = 0;
                        9'd497 : M_next[48:0] = 0;
                        9'd498 : M_next[49:0] = 0;
                        9'd499 : M_next[50:0] = 0;
                        9'd500 : M_next[51:0] = 0;
                        9'd501 : M_next[52:0] = 0;
                        9'd502 : M_next[53:0] = 0;
                        9'd503 : M_next[54:0] = 0;
                        9'd504 : M_next[55:0] = 0;
                        9'd505 : M_next[56:0] = 0;
                        9'd506 : M_next[57:0] = 0;
                        9'd507 : M_next[58:0] = 0;
                        9'd508 : M_next[59:0] = 0;
                        9'd509 : M_next[60:0] = 0;
                        9'd510 : M_next[61:0] = 0;
                        9'd511 : M_next[62:0] = 0;
                        default: M_next = M;
                    endcase
                    ok_next = 1'b1;
                    state_next = WAIT_CALLED;
                    state_return_next = ZERO;
                end
            end
            
            LENGTH: begin // Esto ocurre siempre para el ultimo, y es independiente de n
                M_next[63:0] = {{(64-N_length){1'b0}},length};
                ok_next = 1'b1;
                state_next = IDLE;
            end
            default: state_next = IDLE;
        endcase
    end
    
    // Flip Flop
    always @(posedge clk) begin
        new_M_ant <= new_M;
        
        if (rst[0]) begin
            state <= IDLE;
            state_return <= IDLE;
            
            ok <= 1'b0;
            new_data <= 1'b0;
        end
        else begin
            state <= state_next;
            state_return <= state_return_next;
            
            ok <= ok_next;
            new_data <= new_data_next;   
        end
        
        if (rst[1]) begin
            M  <= 512'd0;
        end
        else begin
            M <= M_next;
        end
    end
endmodule