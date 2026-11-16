module safecrack_pro_fsm (
    input logic clk, 
    input logic reset_n,    // KEY[0] - ativo baixo
    input logic btn_conf,    // KEY[1] - botão de confirmação
    input logic senha_correta,    // sinal de validação da senha
    input logic fim_tempo,    // sinal de término do timer

    output logic [2:0] indice_digito,   // índice do dígito atual (1 a 4)   
    output logic salvar_digito,      // "gravar" dígito atual no registrador de senha
    output logic salvar_nova_senha,   // sobrescreve a senha gravada com a nova senha   
    output logic verificar_senha,    // compara a senha
    output logic iniciar_timer_5s,   // inicia timer de sucesso
    output logic iniciar_timer_3s,   // inicia timer de erro
    output logic ativa_led_verde,   // acende LED verde 
    output logic ativa_led_vermelho   // acende LED vermelho 
);
    typedef enum logic [3:0] {
        ESPERA, EDITAR_1, EDITAR_2, EDITAR_3, EDITAR_4, VALIDAR,
        ABERTO, ERRO_TRAVADO, NOVA_SENHA_1, NOVA_SENHA_2,
        NOVA_SENHA_3, NOVA_SENHA_4, SALVAR_NOVA_SENHA
    } estados_t;

    estados_t estado_atual, proximo_estado;

    // registrador de estado
    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) estado_atual <= EDITAR_1;
        else estado_atual <= proximo_estado;
    end

    // lógica de próximo estado e saídas
    always_comb begin
        // valores padrão para evitar latches
        proximo_estado = estado_atual;
        indice_digito = 3'd0;
        salvar_digito = 1'b0;
        salvar_nova_senha = 1'b0;
        verificar_senha = 1'b0;
        iniciar_timer_5s = 1'b0;
        iniciar_timer_3s = 1'b0;
        ativa_led_verde = 1'b0;
        ativa_led_vermelho = 1'b0;

        case (estado_atual)
            EDITAR_1: begin
                indice_digito = 3'd1;
                if (btn_conf) begin
                    salvar_digito = 1'b1; proximo_estado = EDITAR_2; end
            end
            EDITAR_2: begin
                indice_digito = 3'd2;
                if (btn_conf) begin
                    salvar_digito = 1'b1; proximo_estado = EDITAR_3; end
            end
            EDITAR_3: begin
                indice_digito = 3'd3;
                if (btn_conf) begin
                    salvar_digito = 1'b1; proximo_estado = EDITAR_4; end
            end
            EDITAR_4: begin
                indice_digito = 3'd4;
                if (btn_conf) begin
                    salvar_digito = 1'b1;
                    verificar_senha = 1'b1;
                    proximo_estado = VALIDAR; end
            end

            VALIDAR: begin
                if (senha_correta) begin
                    iniciar_timer_5s = 1'b1;
                    proximo_estado = ABERTO; end
                else begin
                    iniciar_timer_3s = 1'b1;
                    proximo_estado = ERRO_TRAVADO; end
            end

            ABERTO: begin
                ativa_led_verde = 1'b1;
                if (btn_conf) proximo_estado = NOVA_SENHA_1;
                else if (fim_tempo) proximo_estado = EDITAR_1;
            end

            ERRO_TRAVADO: begin
                ativa_led_vermelho = 1'b1;
                if (fim_tempo) proximo_estado = EDITAR_1;
            end

            // fluxo de nova senha
            NOVA_SENHA_1: begin
                indice_digito = 3'd1;
                ativa_led_verde = 1'b1;
                ativa_led_vermelho = 1'b1;
                if (btn_conf) begin
                    salvar_digito = 1'b1; proximo_estado = NOVA_SENHA_2; end
            end
            NOVA_SENHA_2: begin
                indice_digito = 3'd2;
                ativa_led_verde = 1'b1;
                ativa_led_vermelho = 1'b1;
                if (btn_conf) begin
                    salvar_digito = 1'b1; proximo_estado = NOVA_SENHA_3; end
            end
            NOVA_SENHA_3: begin
                indice_digito = 3'd3;
                ativa_led_verde = 1'b1;
                ativa_led_vermelho = 1'b1;
                if (btn_conf) begin
                    salvar_digito = 1'b1; proximo_estado = NOVA_SENHA_4; end
            end
            NOVA_SENHA_4: begin
                indice_digito = 3'd4;
                ativa_led_verde = 1'b1;
                ativa_led_vermelho = 1'b1;
                if (btn_conf) begin
                    salvar_digito = 1'b1;
                    proximo_estado = SALVAR_NOVA_SENHA; end
            end

            SALVAR_NOVA_SENHA: begin
                salvar_nova_senha = 1'b1;
                proximo_estado = EDITAR_1;
            end
            default: proximo_estado = EDITAR_1;
        endcase
    end
endmodule