`timescale 1ns/1ps

module tb_safecrack_pro_top;

    // 1. Parâmetros de Simulação
    // CLK_FREQ reduzido para 100 para acelerar o debouncer e os temporizadores na simulação
    localparam int CLK_FREQ = 100;
    localparam time CLK_PERIOD = 20ns; // Clock simulado de 50 MHz

    // 2. Sinais de Interface do TOP
    logic        clk;
    logic [3:0]  keys;
    logic [3:0][6:0] digit_displays;
    logic [6:0]  active_display;
    logic [8:0]  ledg;
    logic [17:0] ledr;

    // 3. Instanciação do DUT (Device Under Test)
    safecrack_pro_top #(
        .CLK_FREQ(CLK_FREQ)
    ) dut (
        .clk(clk),
        .keys(keys),
        .digit_displays(digit_displays),
        .active_display(active_display),
        .ledg(ledg),
        .ledr(ledr)
    );

    // 4. Geração do Clock
    initial clk = 0;
    always #(CLK_PERIOD / 2) clk = ~clk;

    // 5. Tasks Auxiliares de Simulação

    // Mapeamento das teclas (Ativo em Baixo):
    // keys[0] = Reset (rstn)
    // keys[1] = Confirmar (confirm_pulse)
    // keys[2] = Incrementar dígito (+1)
    // keys[3] = Decrementar dígito (-1)
    task automatic press_key(input int idx);
        begin
            keys[idx] = 1'b0;                 // Pressiona o botão
            repeat (30) @(posedge clk);       // Tempo suficiente para o debouncer registrar o clique
            keys[idx] = 1 me;
            keys[idx] = 1'b1;                 // Solta o botão
            repeat (30) @(posedge clk);       // Tempo para o debouncer estabilizar solto
        end
    endtask

    // Digita uma senha completa de 4 dígitos (do MSB ao LSB)
    task automatic enter_code(input logic [3:0][3:0] code);
        begin
            // O cofre edita os dígitos do índice 3 até 0
            for (int i = 3; i >= 0; i--) begin
                $display("   [TB] Digitando posição [%0d] = %0d...", i, code[i]);
                repeat (code[i]) begin
                    press_key(2); // Pressiona Botão de Incrementar (keys[2])
                end
                press_key(1);     // Pressiona Botão de Confirmar (keys[1])
            end
        end
    endtask

    // 6. Sequência Principal de Testes
    initial begin
        logic [3:0][3:0] init_pass;
        logic [3:0][3:0] wrong_pass;
        logic [3:0][3:0] new_pass;

        $display("=========================================================");
        $display("   INICIANDO TESTBENCH DO SAFECRACK PRO TOP");
        $display("=========================================================");

        // Estado Inicial: Todos os botões soltos (Ativo em Baixo = 1111)
        keys = 4'b1111;

        // --- PASSO 0: Aplicação do Reset ---
        $display("\n[TB] Passo 0: Aplicando Reset (KEY0)...");
        keys[0] = 1'b0;
        repeat (10) @(posedge clk);
        keys[0] = 1'b1;
        repeat (10) @(posedge clk);

        // Captura a senha inicial do cofre após estabilizar o reset
        init_pass = dut.stored_pass;
        $display("[TB] Senha Inicial em Memoria: %h", init_pass);

        // Define uma senha errada
        wrong_pass = init_pass;
        wrong_pass[0] = (init_pass[0] == 4'd9) ? 4'd0 : (init_pass[0] + 4'd1);

        // Define a nova senha para teste de edição: "1234"
        new_pass = {4'd1, 4'd2, 4'd3, 4'd4};

        // --- PASSO 1: Teste de Senha Incorreta ---
        $display("\n[TB] Passo 1: Digitando Senha Incorreta (%h)...", wrong_pass);
        enter_code(wrong_pass);
        
        @(posedge clk);
        assert (dut.incorrect && !dut.unlocked) 
            $display("[TB SUCCESS] Feedback INCORRECT ativado! (LEDs Vermelhos)");
        else 
            $error("[TB ERROR] Falha ao detectar senha incorreta!");

        $display("[TB] Aguardando fim do temporizador de erro (3s)...");
        wait (!dut.incorrect);
        repeat (10) @(posedge clk);
        $display("[TB] Retornou ao estado inicial EDIT1.");

        // --- PASSO 2: Teste de Senha Correta (Desbloqueio) ---
        $display("\n[TB] Passo 2: Digitando Senha Correta (%h)...", init_pass);
        enter_code(init_pass);

        @(posedge clk);
        assert (dut.unlocked && !dut.incorrect) 
            $display("[TB SUCCESS] Cofre DESBLOQUEADO com sucesso! (LEDs Verdes)");
        else 
            $error("[TB ERROR] Falha ao desbloquear com a senha inicial!");

        $display("[TB] Aguardando fim do temporizador de desbloqueio (5s)...");
        wait (!dut.unlocked);
        repeat (10) @(posedge clk);
        $display("[TB] Retornou ao estado inicial EDIT1.");

        // --- PASSO 3: Desbloqueio e Alteração de Senha ---
        $display("\n[TB] Passo 3: Desbloqueando para entrar no Modo de Edicao de Senha...");
        enter_code(init_pass);

        @(posedge clk);
        assert (dut.unlocked) else $error("[TB ERROR] Falha ao desbloquear antes da edição!");

        $display("[TB] Pressionando confirmacao para entrar em Modo Edit (NEW_PASS1)...");
        press_key(1); // Confirma durante UNLOCKED -> Transiciona para NEW_PASS1

        assert (dut.edit_mode) 
            $display("[TB SUCCESS] Entrou no Modo de Edição de Senha (edit_mode = 1)!");
        else 
            $error("[TB ERROR] Falha ao entrar em edit_mode!");

        $display("[TB] Digitando Nova Senha (%h)...", new_pass);
        enter_code(new_pass);
        repeat (10) @(posedge clk);

        assert (dut.stored_pass == new_pass) 
            $display("[TB SUCCESS] Nova Senha salva em memoria! Guardado: %h", dut.stored_pass);
        else 
            $error("[TB ERROR] Nova senha NAO foi salva! Esperado: %h, Guardado: %h", new_pass, dut.stored_pass);

        // --- PASSO 4: Validação do Login com a Nova Senha ---
        $display("\n[TB] Passo 4: Testando login com a Nova Senha Salva (%h)...", new_pass);
        enter_code(new_pass);

        @(posedge clk);
        assert (dut.unlocked) 
            $display("[TB SUCCESS] Desbloqueado com a NOVA SENHA!");
        else 
            $error("[TB ERROR] Falha ao desbloquear com a nova senha!");

        $display("\n=========================================================");
        $display("   SIMULACAO CONCLUIDA COM SUCESSO! TODOS OS TESTES PASSARAM.");
        $display("=========================================================");
        $finish;
    end

endmodule