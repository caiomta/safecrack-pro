`timescale 1ns/1ps

module input_handler_tb;
    localparam int CLK_FREQ = 1000;  
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

    task automatic press_key(input int idx);
        keys[idx] = 1'b1;
        repeat (30) @(posedge clk);  // tempo suficiente para vencer o debounce
        keys[idx] = 1'b0;
        repeat (30) @(posedge clk);
    endtask

    initial begin
        rstn = 1'b0;
        keys = '0;
        repeat (5) @(posedge clk);
        rstn = 1'b1;
        repeat (5) @(posedge clk);

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

        // testa ruído/bouncing rápido (não deve alterar digit_val)
        keys[1] = 1'b1;
        repeat (2) @(posedge clk);
        keys[1] = 1'b0;
        repeat (20) @(posedge clk);
        assert (digit_val == 4'd0) else $error("Debounce falhou ao filtrar ruido");

        $display("Simulacao concluida.");
        $finish;
    end
endmodule