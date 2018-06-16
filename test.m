%% Puerto serial
if (exist('s'))
    fclose(s);
end

clear all

s = serial('COM4', 'BaudRate', 115200,'DataBits', 8, 'OutputBufferSize', 1024, 'InputBufferSize', 1024);
fopen(s);

%% Vectores de prueba
a1 = uint8([0:31 0:31]);
a2 = uint8(0:2:31);
a3 = uint8(zeros(1,64) + 255);
a4 = uint8([1 9 0 7 1 9 9 4]);
a5 = uint8(ones(1,80));
a6 = 01;
a7 = uint8([0:31 0:31 (31 - [0:31]) (31 - [0:31])]);

word = {a1; a2; a3; a4; a5; a6; a7};

%% Generacion de la palabra en hexadecimal

word_hex = cell(length(word),1);

for j = 1:length(word)

    for i = 1:length(word{j})
        word_hex{j} = strcat(word_hex{j},dec2hex(word{j}(i),2));
    end

end

%Palabras en hexadecimal
word_hex

%% Generacion de largos
length_bin = cell(length(word),1);
msg1 = cell(length(word),1);
msg2 = cell(length(word),1);

for j = 1:length(word)
    % Calcula el largo de la palabra
    length_bin{j} = de2bi(length(word{j})*8,16,'left-msb');

    %Guarda en vectores listos para enviar el largo de la palabra
    msg1{j} = bi2de(length_bin{j}(9:16),'left-msb');
    msg2{j} = bi2de(length_bin{j}(1:8),'left-msb');
end

%% Envio de mensajes
for j = 1:length(word)
    fwrite(s,msg1{j});
    fwrite(s,msg2{j});
    fwrite(s,word{j});
end