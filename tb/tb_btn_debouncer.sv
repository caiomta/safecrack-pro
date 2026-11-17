`timescale 1ns/1ps

module btn_debouncer_tb;
    localparam int CLK_FREQ = 1000;
    localparam int DEB_MS = 5;  // DEB_CYCLES = 5
    localparam time CLK_PERIOD = 10ns;

    logic clk, rstn, btn;
    logic btn_pulse;

    btn_debouncer #(
        .CLK_FREQ(CLK_FREQ),
        .DEB_MS(DEB_MS)
    ) dut (.*);

    initial clk = 0;
    always #(CLK_PERIOD / 2) clk = ~clk;

    initial begin
        rstn = 1'b0;
        btn = 1'b1;
        repeat (3) @(posedge clk);
        rstn = 1'b1;
        repeat (3) @(posedge clk);

        // ruído de 4 ciclos (menor que DEB_CYCLES = 5 -> não deve gerar pulso)
        btn = 1'b0;
        repeat (4) @(posedge clk);
        btn = 1'b1;
        repeat (6) @(posedge clk);
        assert (!btn_pulse) else $error("Pulso indevido em ruido curto");

        // clique válido + segurar botão (deve gerar apenas 1 pulso de 1 ciclo)
        btn = 1'b0;
        repeat (15) @(posedge clk);
        assert (!btn_pulse) else $error("btn_pulse ficou travado em 1");

        // ruído na soltura (não deve disparar segundo pulso)
        btn = 1'b1;
        repeat (2) @(posedge clk);
        btn = 1'b0;
        repeat (2) @(posedge clk);
        btn = 1'b1;
        repeat (10) @(posedge clk);
        assert (!btn_pulse) else $error("Pulso falso na soltura do botao");

        $display("Simulacao concluida.");
        $finish;
    end

    // monitor contínuo: todo pulso deve durar exatamente 1 ciclo de clock
    always @(posedge clk) begin
        if (rstn && btn_pulse) begin
            @(posedge clk);
            assert (!btn_pulse) else $error("btn_pulse durou mais de 1 ciclo");
        end
    end
endmodule