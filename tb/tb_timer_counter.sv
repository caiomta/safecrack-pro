`timescale 1ns/1ps

module timer_counter_tb;
    localparam int CLK_FREQ = 2;  // 3s = 6 ciclos | 5s = 10 ciclos
    localparam time CLK_PERIOD = 10ns;

    logic clk, rstn, timer_enable, timer_mode;
    logic timer_done;

    timer_counter #(
        .CLK_FREQ(CLK_FREQ)
    ) dut (.*);

    initial clk = 0;
    always #(CLK_PERIOD / 2) clk = ~clk;

    initial begin
        rstn = 1'b0;
        timer_enable = 1'b0;
        timer_mode = 1'b0;
        repeat (3) @(posedge clk);
        rstn = 1'b1;
        @(posedge clk);

        // modo 0 (3s -> 6 ciclos)
        timer_enable = 1'b1;
        repeat (5) @(posedge clk);
        assert (!timer_done) else $error("timer_done subiu antes dos 6 ciclos");
        @(posedge clk);
        #1;
        assert (timer_done) else $error("timer_done nao subiu no 6o ciclo");

        // desabilitar deve zerar imediatamente no proximo clock
        timer_enable = 1'b0;
        @(posedge clk);
        #1;
        assert (!timer_done) else $error("timer_done nao zerou ao desabilitar");

        // modo 1 (5s -> 10 ciclos)
        timer_mode = 1'b1;
        timer_enable = 1'b1;
        repeat (9) @(posedge clk);
        assert (!timer_done) else $error("timer_done subiu antes dos 10 ciclos");
        @(posedge clk);
        #1;
        assert (timer_done) else $error("timer_done nao subiu no 10o ciclo");

        $display("Simulacao concluida.");
        $finish;
    end
endmodule