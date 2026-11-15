`timescale 1ns/1ps  //unidade de tempo -> 1ns, precisão de 1ps

module tb_password_manager;

// Sinais de controle do DUT
logic clk;
logic reset_pass;
logic [3:0][3:0] entered_pass;
logic save_pass;

// Sinais p/ ler as respostas do DUT
logic match_pass;
logic [3:0][3:0] stored_pass;

// instanciação do módulo sob teste
password_manager dut(
    .clk (clk),
    .reset_pass (reset_pass),
    .entered_pass (entered_pass),
    .save_pass (save_pass),
    .match_pass (match_pass),
    .stored_pass (stored_pass)
);

// Geração do clk de 50MHz (Período de 20ns)
initial begin
    clk = 0;
    forever #10 clk = ~clk; //inverte o clk a cada 10ns
end


// BLOCO DE TESTE
initial begin
    // 0. estado inicial
    save_pass = 0;
    entered_pass = '{4'd0, 4'd0, 4'd0, 4'd0};
    reset_pass = 0; // inativo
    #15;

    // teste 1: Aplicar reset inicial
    $display("\n[TESTE 1] Testando Reset Inicial...");
    reset_pass = 1; //pulso (1)
    #20;
    reset_pass = 0; // retorna ao inicial
    #10;

    if (stored_pass == '{4'd0, 4'd0, 4'd0, 4'd0})
        $display("-> SUCESSO: Senha padrão 0000 restaurada!");
    else 
        $error("-> ERRO: Reset falhou! Senha armazenada: %h", stored_pass);

    // Teste 2: Senha incorreta (1234)
    $display("\n[TESTE 2] Testando senha incorreta (1234)...");
    entered_pass = '{4'd1, 4'd2, 4'd3, 4'd4};
    #10;

    if (match_pass == 0)
        $display("-> SUCESSO: match_pass = 0 (senha incorreta rejeitada)");
    else
        $error("-> Erro: match_pass = 1 para senha incorreta");
    

    // teste 3: tentativa senha correta (0000)
    $display("\n[Teste 3] Testando senha correta (0000)");
    entered_pass = '{4'd0, 4'd0, 4'd0, 4'd0};
    #10;

    if (match_pass == 1)
        $display("-> SUCESSO: match_pass = 1 (Cofre liberado)");
    else
        $error("-> ERRO: match_pass = 0 para senha correta!");


    //teste 4: Gravar nova senha no modo edição (9876)
    $display("\n[TESTE 4] Gravando nova senha (9876)");
    entered_pass = '{4'd9, 4'd8, 4'd7, 4'd6};

    //simula pulso de 1 ciclo vindo da FMS
    @(negedge clk);
    save_pass = 1;
    @(negedge clk);
    save_pass = 0;

    #10;
    if (stored_pass == '{4'd9, 4'd8, 4'd7, 4'd6})
        $display("-> Sucesso: Nova senha 9876 salva na memoria");
    else
        $error("-> ERRO: Falha ao gravar nova senha!");
    

    // teste 5: Revalidação com nova senha
    $display("\n[TESTE 5] Validando com a nova senha.");

    // teste de senha antiga (deve falhar)
    entered_pass = '{4'd0, 4'd0, 4'd0, 4'd0};
    #10;

    if (match_pass == 0)
        $display("-> SUCESSO: Senha antiga inválida.");
    else 
        $error("-> ERRO: Senha antiga continua sendo aceita.");
    
    // testar  nova senha (9876) -> deve funcionar
    entered_pass = '{4'd9, 4'd8, 4'd7, 4'd6};
    #10;

    if (match_pass == 1)
        $display("-> SUCESSO: Nova senha 9876 ACEITA com sucesso!");
    else 
        $error("-> ERRO: Nova senha não foi aceita.");
    
    $display(" OS TESTES FORAM CONCLUIDOS! ");
    $finish;
end
    
endmodule