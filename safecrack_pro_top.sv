module safecrack_pro_top (
    input logic CLOCK_50, // recebe direto da placa
    input logic [3:0] KEY,   // os 4 botões físicos da placa
    output logic [6:0] HEX0, HEX1, HEX2, HEX3, HEX4  // displays de 7 segmentos   
    output logic [8:0] LEDG, 
    output logic [17:0] LEDR
);
    logic reset_n, btn_conf;
    assign reset_n = KEY[0];   // rest no botão 0

    // pulso dos botões (detecta quando o botão é pressionado)
    logic [3:1] botao_sync_0, botao_sync_1; // filtros para evitar toque duplo
    logic pulso_confirma, pulso_incrementa, pulso_decrementa;

    always_ff @(posedge CLOCK_50 or negedge reset_n) begin
        if (!reset_n) begin
            botao_sync_0 <= 3'b111;
            botao_sync_1 <= 3'b111; end
        else begin
            botao_sync_0 <= KEY[3:1];
            botao_sync_1 <= botao_sync_0; end
    end

    // o botão é ativo em baixo (0), então o pulso é gerado quando o botão vai de 1 para 0
    assign pulso_confirma = ~botao_sync_0[1] & botao_sync_1[1];
    assign pulso_incrementa = ~botao_sync_0[2] & botao_sync_1[2];
    assign pulso_decrementa = ~botao_sync_0[3] & botao_sync_1[3];

    // sinais conectando com a FSM
    logic [2:0] indice_digito;
    logic salvar_digito, salvar_nova_senha, verificar_senha;
    logic iniciar_timer_5s, iniciar_timer_3s, fim_tempo;
    logic ativa_led_verde, ativa_led_vermelho;
    logic senha_correta;

    // variáveis do cofre
    logic [3:0] valor_digito_ativo;
    logic [3:0] senha_digitada [3:0];   // senha digitada pelo usuário
    logic [3:0] senha_armazenada [3:0];  // senha armazenada no cofre

    // temporizador 
    logic [27:0] contador_tempo;   // contador de tempo (28 bits para contar até 5s com clock de 50MHz)
    logic timer_ativo;
    logic [27:0] tempo_limite;   // tempo limite para o temporizador

    always_ff @(posedge CLOCK_50 or negedge reset_n) begin
        if (!reset_n) begin
            contador_tempo <= 0;
            timer_ativo <= 0;
            fim_tempo <= 0; end
        else begin
            fim_tempo <= 0;
            if (iniciar_timer_5s) begin
                contador_tempo <= 0;
                tempo_limite <= 28'd250_000_000; // 5 segundos com clock de 50MHz
                timer_ativo <= 1; end
            else if (iniciar_timer_3s) begin
                contador_tempo <= 0;
                tempo_limite <= 28'd150_000_000; // 3 segundos com clock de 50MHz
                timer_ativo <= 1; end
            else if (timer_ativo) begin
                if (contador_tempo == tempo_limite - 1) begin
                    fim_tempo <= 1;
                    timer_ativo <= 0; end
                else begin
                    contador_tempo <= contador_tempo + 1; end
            end
        end
    end

    // controle no valor do display que está piscando/sendo editado (0 a 9)
    always_ff @(posedge CLOCK_50 or negedge reset_n) begin
        if (!reset_n) begin
            valor_digito_ativo <= 4'd0; end
        else if (salvar_digito || fim_tempo) begin
            valor_digito_ativo <= 4'd0; end // zera ao pular pro próximo ou após o timer
        else if (indice_digito != 0) begin
            if (pulso_incrementa)
                valor_digito_ativo <= (valor_digito_ativo == 4'd9) ? 4'd0 : valor_digito_ativo + 1;
            else if (pulso_decrementa)
                valor_digito_ativo <= (valor_digito_ativo == 4'd0) ? 4'd9 : valor_digito_ativo - 1;
        end
    end

    // memória da senha 
    always_ff @(posedge CLOCK_50 or negedge reset_n) begin
        if (!reset_n) begin
            senha_digitada[0] <= 0; senha_digitada[1] <= 0; senha_digitada[2] <= 0; senha_digitada[3] <= 0;
            senha_armazenada[0] <= 0; senha_armazenada[1] <= 0; senha_armazenada[2] <= 0; senha_armazenada[3] <= 0; end // senha inicial 0000
        else begin
            if (salvar_digito && indice_digito >= 1 && indice_digito <= 4) begin
                senha_digitada[indice_digito - 1] <= valor_digito_ativo; end
            if (salvar_nova_senha) begin
                senha_armazenada[0] <= senha_digitada[0];
                senha_armazenada[1] <= senha_digitada[1];
                senha_armazenada[2] <= senha_digitada[2];
                senha_armazenada[3] <= senha_digitada[3]; end
        end
    end

    // vericação de acerto
    assign senha_correta = (senha_digitada[0] == senha_armazenada[0]) &&
                           (senha_digitada[1] == senha_armazenada[1]) &&
                           (senha_digitada[2] == senha_armazenada[2]) &&
                           (senha_digitada[3] == senha_armazenada[3]);

    // instanciando a FSM
    safecrack_pro_fsm2 fsm (
        .clk(CLOCK_50), .reset_n(reset_n), .pulso_confirma(pulso_confirma),
        .senha_correta(senha_correta), .fim_tempo(fim_tempo),
        .indice_digito(indice_digito), .salvar_digito(salvar_digito),
        .salvar_nova_senha(salvar_nova_senha), .verificar_senha(verificar_senha),
        .iniciar_timer_5s(iniciar_timer_5s), .iniciar_timer_3s(iniciar_timer_3s),
        .ativa_led_verde(ativa_led_verde), .ativa_led_vermelho(ativa_led_vermelho)
    );

    // lógica visual para os displays
    logic [3:0] tela [3:0];
    assign tela[0] = (indice_digito == 1) ? valor_digito_ativo : (indice_digito > 1 || indice_digito == 0) ? senha_digitada[0] : 4'd0;
    assign tela[1] = (indice_digito == 2) ? valor_digito_ativo : (indice_digito > 2 || indice_digito == 0) ? senha_digitada[1] : 4'd0;
    assign tela[2] = (indice_digito == 3) ? valor_digito_ativo : (indice_digito > 3 || indice_digito == 0) ? senha_digitada[2] : 4'd0;
    assign tela[3] = (indice_digito == 4) ? valor_digito_ativo : (indice_digito > 4 || indice_digito == 0) ? senha_digitada[3] : 4'd0;

    // decodificador de 7 segmentos 
    function logic [6:0] converte_bcd_display(input logic [3:0 bcd]);
        case (bcd)
            4'd0: return 7'b1000000; // 0
            4'd1: return 7'b1111001; // 1
            4'd2: return 7'b0100100; // 2
            4'd3: return 7'b0110000; // 3
            4'd4: return 7'b0011001; // 4
            4'd5: return 7'b0010010; // 5
            4'd6: return 7'b0000010; // 6
            4'd7: return 7'b1111000; // 7   
            4'd8: return 7'b0000000; // 8
            4'd9: return 7'b0011000; // 9
            default: return 7'b1111111; // off
        endcase
    endfunction

    assign HEX3 = converte_bcd_display(tela[0]);
    assign HEX2 = converte_bcd_display(tela[1]);
    assign HEX1 = converte_bcd_display(tela[2]);
    assign HEX0 = converte_bcd_display(tela[3]);

    // HEX4 mostra qual digito ta sendo editado
    assign HEX4 = (indice_digito == 0) ? 7'b1111111 : converte_bcd_display({1'b0, indice_digito}); // mostra 1 a 4 ou nada

    // LEDs verdes e vermelhos
    assign LEDG = ativa_led_verde ? 9'h1FF : 9'h000; //  verdes acesos ou apagados
    assign LEDR = ativa_led_vermelho ? 18'h3FFFF : 18'h00000; // vermelhos acesos ou apagados
endmodule