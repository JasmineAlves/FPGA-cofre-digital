module cofre_digital(
    input MAX10_CLK1_50,      // Clock de 50MHz
    input [9:0] SW,           // Switches para entrada dos dígitos (SW3-SW0)
    input [1:0] KEY,          // Botões (KEY0 para confirmar, KEY1 para reset)
    output [9:0] LEDR,        // LEDs para status
    output [7:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5 // Displays de 7 segmentos
);

    // Parâmetros e definições
    parameter SENHA0 = 4'b0011;  // Dígito 1 da senha = 3
    parameter SENHA1 = 4'b0000;  // Dígito 2 da senha = 0
    parameter SENHA2 = 4'b0001;  // Dígito 3 da senha = 1
    parameter SENHA3 = 4'b0101;  // Dígito 4 da senha = 5
    parameter TEMPO_BLOQUEIO = 29'd500_000_000; // 10 segundos
    parameter TEMPO_ERRO = 29'd15_000_000; // 3 segundos
     
    // ESTADOS
    parameter [3:0] 
        INICIO      = 4'b0000,
        DIGITO1     = 4'b0001, 
        DIGITO2     = 4'b0010, 
        DIGITO3     = 4'b0011, 
        DIGITO4     = 4'b0100,
        VERIFICACAO = 4'b0101,
        DESBLOQUEADO= 4'b0110,
        ERRO        = 4'b0111,
        BLOQUEADO   = 4'b1000;
    
    reg [3:0] estado_atual;
    reg [3:0] digitos [0:3];
    reg [1:0] tentativas;
    reg [28:0] contador_tempo;
    reg [28:0] contador_erro;
    reg [28:0] contador_bloqueio;  // Contador específico para o estado BLOQUEADO
    reg [4:0] contagem;
    reg key0_reg;
    
    // Debounce para KEY[0]
    always @(posedge MAX10_CLK1_50 or negedge KEY[1]) begin
        if (!KEY[1]) begin // Reset
            key0_reg <= 1'b0;
        end else begin
            key0_reg <= KEY[0];
        end
    end
    
    wire key0_pressed = ~KEY[0] & key0_reg;
    
    // Contador de bloqueio - só conta durante o estado BLOQUEADO
    always @(posedge MAX10_CLK1_50 or negedge KEY[1]) begin
        if (!KEY[1]) begin // Reset
            contador_bloqueio <= 29'b0;
            contagem <= 5'b0;
        end else begin
            if (estado_atual == BLOQUEADO) begin
                contador_bloqueio <= contador_bloqueio + 1;
                if (contador_bloqueio >= TEMPO_BLOQUEIO) begin
                    contador_bloqueio <= 0;
                    contagem <= contagem + 1;
                end
                if (contagem > 9) contagem <= 0;
            end else begin
                contador_bloqueio <= 0;
                contagem <= 0;
            end
        end
    end
    
    // Máquina de Estados
    always @(posedge MAX10_CLK1_50 or negedge KEY[1]) begin
        if (!KEY[1]) begin // Reset
            estado_atual <= INICIO;
            contador_tempo <= 29'b0;
            contador_erro <= 29'b0;
            digitos[0] <= 4'b1111;
            digitos[1] <= 4'b1111;
            digitos[2] <= 4'b1111;
            digitos[3] <= 4'b1111;
            tentativas <= 2'b00;
        end else begin
            case (estado_atual)
                INICIO: if (key0_pressed) estado_atual <= DIGITO1;
                
                DIGITO1: if (key0_pressed) begin
                    digitos[0] <= SW[3:0];
                    estado_atual <= DIGITO2;
                end
                
                DIGITO2: if (key0_pressed) begin
                    digitos[1] <= SW[3:0];
                    estado_atual <= DIGITO3;
                end
                
                DIGITO3: if (key0_pressed) begin
                    digitos[2] <= SW[3:0];
                    estado_atual <= DIGITO4;
                end
                
                DIGITO4: if (key0_pressed) begin
                    digitos[3] <= SW[3:0];
                    estado_atual <= VERIFICACAO;
                end
                
                VERIFICACAO: begin
                    if (digitos[0]==SENHA0 && digitos[1]==SENHA1 && 
                        digitos[2]==SENHA2 && digitos[3]==SENHA3) begin
                        tentativas <= 2'b00;
                        estado_atual <= DESBLOQUEADO;
                    end else begin
                        if (tentativas == 2'b10) begin
                            estado_atual <= BLOQUEADO;
                        end
                        else begin
                            tentativas <= tentativas + 1;
                            estado_atual <= ERRO;
                        end
                    end
                end
                
                DESBLOQUEADO: if (!KEY[1]) estado_atual <= INICIO;
                
                ERRO: begin
                    contador_erro <= contador_erro + 1;
                    if (contador_erro >= TEMPO_ERRO) begin
                        contador_erro <= 29'b0;
                        estado_atual <= INICIO;
                    end
                end
                
                BLOQUEADO: begin
                    if (contagem >= 1) begin
                        tentativas <= 2'b00;
                        estado_atual <= INICIO;
                    end
                end
                
                default: estado_atual <= INICIO;
            endcase
        end
    end
	 
    // Função de conversão para display de 7 segmentos
    function [7:0] num_to_seg;
        input [3:0] num;
        begin
            case (num)
                4'b0000: num_to_seg = 8'b11000000; // 0
                4'b0001: num_to_seg = 8'b11111001; // 1
                4'b0010: num_to_seg = 8'b10100100; // 2
                4'b0011: num_to_seg = 8'b10110000; // 3
                4'b0100: num_to_seg = 8'b10011001; // 4
                4'b0101: num_to_seg = 8'b10010010; // 5
                4'b0110: num_to_seg = 8'b10000010; // 6
                4'b0111: num_to_seg = 8'b11111000; // 7
                4'b1000: num_to_seg = 8'b10000000; // 8
                4'b1001: num_to_seg = 8'b10010000; // 9
                default: num_to_seg = 8'b11111111; // Apagado
            endcase
        end
    endfunction
    
    // Controle dos displays
    reg [7:0] hex [5:0];
    
    always @(*) begin
        case (estado_atual)
            INICIO: begin
                hex[5] = 8'b11111111;
                hex[4] = 8'b11111111;
                hex[3] = 8'b10111111; // "-"
                hex[2] = 8'b10111111; // "-"
                hex[1] = 8'b10111111; // "-"
                hex[0] = 8'b10111111; // "-"
            end
            
            DIGITO1: begin
                hex[5] = 8'b11111111;
                hex[4] = 8'b11111111;
                hex[3] = num_to_seg(digitos[0]);
                hex[2] = 8'b10111111;
                hex[1] = 8'b10111111;
                hex[0] = 8'b10111111;
            end
            
            DIGITO2: begin
                hex[5] = 8'b11111111;
                hex[4] = 8'b11111111;
                hex[3] = num_to_seg(digitos[0]);
                hex[2] = num_to_seg(digitos[1]);
                hex[1] = 8'b10111111;
                hex[0] = 8'b10111111;
            end
            
            DIGITO3: begin
                hex[5] = 8'b11111111;
                hex[4] = 8'b11111111;
                hex[3] = num_to_seg(digitos[0]);
                hex[2] = num_to_seg(digitos[1]);
                hex[1] = num_to_seg(digitos[2]);
                hex[0] = 8'b10111111;
            end
            
            DIGITO4: begin
                hex[5] = 8'b11111111;
                hex[4] = 8'b11111111;
                hex[3] = num_to_seg(digitos[0]);
                hex[2] = num_to_seg(digitos[1]);
                hex[1] = num_to_seg(digitos[2]);
                hex[0] = num_to_seg(digitos[3]);
            end
            
            VERIFICACAO: begin
                hex[5] = 8'b11111111;
                hex[4] = 8'b11111111;
                hex[3] = num_to_seg(digitos[0]);
                hex[2] = num_to_seg(digitos[1]);
                hex[1] = num_to_seg(digitos[2]);
                hex[0] = num_to_seg(digitos[3]);
            end
            
            DESBLOQUEADO: begin
                hex[5] = 8'b11000000; // '0'
                hex[4] = 8'b10001100; // 'P'
                hex[3] = num_to_seg(digitos[0]);
                hex[2] = num_to_seg(digitos[1]);
                hex[1] = num_to_seg(digitos[2]);
                hex[0] = num_to_seg(digitos[3]);
            end
            
            ERRO: begin
                hex[5] = 8'b10000110; // 'E'
                hex[4] = 8'b10101111; // 'r'
                hex[3] = num_to_seg(digitos[0]);
                hex[2] = num_to_seg(digitos[1]);
                hex[1] = num_to_seg(digitos[2]);
                hex[0] = num_to_seg(digitos[3]);
            end
            
            BLOQUEADO: begin
                hex[5] = 8'b10000011;  // 'b'
                hex[4] = 8'b11000111;  // 'L'
                hex[3] = num_to_seg(digitos[0]);
                hex[2] = num_to_seg(digitos[1]);
                hex[1] = num_to_seg(digitos[2]);
                hex[0] = num_to_seg(digitos[3]);
            end
            
            default: begin
                hex[5] = 8'b11111111;
                hex[4] = 8'b11111111;
                hex[3] = 8'b11111111;
                hex[2] = 8'b11111111;
                hex[1] = 8'b11111111;
                hex[0] = 8'b11111111;
            end
        endcase
    end
    
    assign HEX5 = hex[5];
    assign HEX4 = hex[4];
    assign HEX3 = hex[3];
    assign HEX2 = hex[2];
    assign HEX1 = hex[1];
    assign HEX0 = hex[0];
    
    // LEDs
    assign LEDR[0] = (estado_atual == DESBLOQUEADO);
    assign LEDR[9] = (estado_atual == ERRO || estado_atual == BLOQUEADO);
    assign LEDR[7:2] = estado_atual;
    
endmodule