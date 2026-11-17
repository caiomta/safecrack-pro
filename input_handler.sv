`timescale 1ns/1ps

module input_handler_tb;
    localparam int CLK_FREQ = 500;  // força DEB_CYCLES = 2 no debouncer
    localparam time CLK_PERIOD = 10ns;

    logic clk, rstn;
    logic [2:0] keys;
    logic [3:0] digit_val;
    logic confirm_pulse;

    input_handler #(
        .CLK_FREQ(CLK_FREQ)
    ) dut (.*);

    initial clk = 0;
    always #(CLK_PERIOD / 2) clk = ~clk;

    // 2 ciclos de sincronizador + 2 ciclos de debounce = 4 ciclos mínimos (6 com folga)
    task automatic press_key(input int idx);
        keys[idx] = 1'b0;
        repeat (6) @(posedge clk);
        keys[idx] = 1'b1;
        repeat (6) @(posedge clk);
    endtask

    initial begin
        rstn = 1'b0;
        keys = '1;  // repouso em 1 (active-low)
        repeat (3) @(posedge clk);
        rstn = 1'b1;
        repeat (3) @(posedge clk);

        // testa decremento com wrap-around (0 -> 9 -> 8)
        press_key(2);
        assert (digit_val == 4'd9) else $error("Falha wrap-around decremento: %0d", digit_val);
        press_key(2);
        assert (digit_val == 4'd8) else $error("Falha decremento: %0d", digit_val);

        // testa incremento com wrap-around (8 -> 9 -> 0 -> 1)
        press_key(1);
        assert (digit_val == 4'd9) else $error("Falha incremento: %0d", digit_val);
        press_key(1);
        assert (digit_val == 4'd0) else $error("Falha wrap-around incremento: %0d", digit_val);
        press_key(1);
        assert (digit_val == 4'd1) else $error("Falha incremento pos-zero: %0d", digit_val);

        // testa confirmação (zera digit_val)
        press_key(0);
        assert (digit_val == 4'd0) else $error("Falha reset por confirmacao: %0d", digit_val);

        // testa ruído de 1 ciclo (menor que DEB_CYCLES = 2, deve ser ignorado)
        keys[1] = 1'b0;
        @(posedge clk);
        keys[1] = 1'b1;
        repeat (6) @(posedge clk);
        assert (digit_val == 4'd0) else $error("Debounce falhou ao filtrar ruido");

        $display("Simulacao concluida.");
        $finish;
    end
endmodule