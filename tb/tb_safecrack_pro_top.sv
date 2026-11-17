`timescale 1ns/1ps

module safecrack_pro_top_tb;
    localparam int CLK_FREQ = 500;
    localparam time CLK_PERIOD = 10ns;

    logic clk;
    logic [3:0] keys;
    logic [3:0][6:0] digit_displays;
    logic [6:0] active_display;
    logic [8:0] ledg;
    logic [17:0] ledr;

    safecrack_pro_top #(
        .CLK_FREQ(CLK_FREQ)
    ) dut (.*);

    initial clk = 0;
    always #(CLK_PERIOD / 2) clk = ~clk;

    // keys[0] = rstn | keys[1] = confirm | keys[2] = inc | keys[3] = dec
    task automatic press_key(input int idx);
        keys[idx] = 1'b0;
        repeat (6) @(posedge clk);
        keys[idx] = 1'b1;
        repeat (6) @(posedge clk);
    endtask

    task automatic enter_code(input logic [3:0][3:0] code);
        for (int i = 3; i >= 0; i--) begin
            repeat (code[i]) press_key(2);  // incrementa até o dígito desejado
            press_key(1);                    // confirma dígito
        end
    endtask

    initial begin
        logic [3:0][3:0] init_pass;
        logic [3:0][3:0] wrong_pass;
        logic [3:0][3:0] new_pass;

        keys = '1;
        keys[0] = 1'b0;
        repeat (4) @(posedge clk);
        keys[0] = 1'b1;
        repeat (4) @(posedge clk);

        init_pass = dut.stored_pass;
        wrong_pass = init_pass;
        wrong_pass[0] = (init_pass[0] == 4'd9) ? 4'd0 : (init_pass[0] + 4'd1);
        new_pass = {4'd1, 4'd2, 4'd3, 4'd4};

        // 1. senha incorreta -> deve acionar incorrect e voltar para EDIT1 após timer
        enter_code(wrong_pass);
        @(posedge clk);
        assert (dut.incorrect && !dut.unlocked) else $error("Falha ao detectar senha incorreta");
        wait (!dut.incorrect);
        repeat (3) @(posedge clk);

        // 2. senha correta -> deve desbloquear e voltar para EDIT1 após timer (5s)
        enter_code(init_pass);
        @(posedge clk);
        assert (dut.unlocked && !dut.incorrect) else $error("Falha ao desbloquear com senha inicial");
        wait (!dut.unlocked);
        repeat (3) @(posedge clk);

        // 3. desbloquear -> confirmar para entrar em edit_mode -> gravar nova senha
        enter_code(init_pass);
        @(posedge clk);
        assert (dut.unlocked) else $error("Falha ao desbloquear antes da edicao");

        press_key(1);  // entra em NEW_PASS1
        assert (dut.edit_mode) else $error("Falha ao entrar em edit_mode");

        enter_code(new_pass);
        repeat (3) @(posedge clk);
        assert (dut.stored_pass == new_pass) else $error("Nova senha nao foi salva: %h", dut.stored_pass);

        // 4. validar login com a nova senha salva
        enter_code(new_pass);
        @(posedge clk);
        assert (dut.unlocked) else $error("Falha ao desbloquear com a nova senha");

        $display("Simulacao concluida com sucesso.");
        $finish;
    end
endmodule