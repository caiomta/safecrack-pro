'timescale 1ns/1ps

module tb_safecrack_pro_top();
    // sinais de entrada para a placa
    logic CLOCK_50;
    logic [3:0] KEY;    

    // sinais de saída da placa (visuais)
    logic [6:0] HEX0, HEX1, HEX2, HEX3, HEX4;
    logic [8:0] LEDG;
    logic [17:0] LEDR;

    // instanciando o top level
    safecrack_pro_top dut (.*);

    // geradorr de clock (periodo de 20ns, frequência de 50MHz)
    initial CLOCK_50 = 0;
    always #10 CLOCK_50 = ~CLOCK_50;

    // simular o dedo do usuário apertando um botão
    task apertar_botao(input int numero_botao);
        KEY[numero_botao] = 0; // botão pressionado (ativo baixo)
        #40;                 
        KEY[numero_botao] = 1; // solta
        #40;                
    endtask

    initial begin
        // inicializa os botões sem serem pressionados (nivel alto)
        KEY = 4'b1111

        // reset inicial
        $$display("Aplicando reset inicial...");
        KEY[0] = 0; #50; KEY[0] = 1; #50;

        // 1. ERRO DE SENHA (usando 1-0-0-0)
        $display("Testando senha incorreta...");
        apertar_botao(2); // KEY[2] incrementa D1
        apertar_botao(1); // KEY[1] confirma D1
        apertar_botao(1); // KEY[1] confirma D2 (D2 = 0)
        apertar_botao(1); // KEY[1] confirma D3 (D3 = 0)
        apertar_botao(1); // KEY[1] confirma D4 e tenta validar a senha
        #1000; // tempo para os leds vermelhos acenderem

        // 2. DESBLOQUEIO INICIAL (usando 0-0-0-0)
        $display("Testando desbloqueio com 0000...");
        KEY[0] = 0; #50; KEY[0] = 1; #50; // reset para limpar a tentativa anterior

        apertar_botao(1); // KEY[1] confirma D1 (D1 = 0)
        apertar_botao(1); // KEY[1] confirma D2 (D2 = 0)
        apertar_botao(1); // KEY[1] confirma D3 (D3 = 0)
        apertar_botao(1); // KEY[1] confirma D4 e tenta validar a senha
        #200; // tempo para os leds verdes acenderem

        // 3. TRANSIÇÃO PARA EDIÇÃO VIA KEY[1] (durante unlocked)
        $display("Testando modo de edição de senha...");
        apertar_botao(1);

        // 4. GRAVAÇÃO DA NOVA SENHA (vamos salvar 2-2-2-2)
        $display("Gravando nova senha 2222...");
        apertar_botao(2); apertar_botao(2); apertar_botao(1); // sobe pra 2 e confirma D1
        apertar_botao(2); apertar_botao(2); apertar_botao(1); // sobe pra 2 e confirma D2
        apertar_botao(2); apertar_botao(2); apertar_botao(1); // sobe pra 2 e confirma D3
        apertar_botao(2); apertar_botao(2); apertar_botao(1); // sobe pra 2, confirma D4 e salva
        #200;

        // 5. TESTE DE DESBLOQUEIO COM A NOVA SENHA
        $display("Testando desbloqueio com a nova senha 2222...");
        apertar_botao(2); apertar_botao(2); apertar_botao(1); 
        apertar_botao(2); apertar_botao(2); apertar_botao(1);
        apertar_botao(2); apertar_botao(2); apertar_botao(1);
        apertar_botao(2); apertar_botao(2); apertar_botao(1);
        #500; // cofre deve abrir novamente

        $display("Fim do teste.");
        $stop;
    end
endmodule
