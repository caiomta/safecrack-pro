module safecrack_pro_fsm #(
    parameter int CLK_FREQ = 50_000_000;
) (
    input logic clk, reset,
    input logic [2:0] btn,
    output logic [3:0] [6:0] digit_displays, // 4 displays de 7 leds
    output logic [6:0] active_digit, // display de 7 leds para indicar o dígito
                                     // sendo modificado no momento
    output logic unlocked, incorrect
);
    localparam int DEB_CYCLES = (
        (CLK_FREQ >= 1000) ? ((CLK_FREQ / 1000) * 15) : 2
    );

    logic [2:0] btn_sync0, btn_sync1; // sincronização para evitar metaestabilidade
    logic btn_active; 
    logic btn_stable;
    logic btn_prev;
    logic btn_pulse;
    logic [$clog2(DEB_CYCLES)-1:0] deb_cnt [2:0];

    @always_ff @(posedge clk) begin
        btn_sync0 <= btn; // apenas sync0 captura o sinal instável de btn
        btn_sync1 <= btn_sync0; // sync1 captura o sinal estabilizado após 1 ciclo de clock
    end

    assign btn_active = ~btn_sync1; // sinal invertido do botão (1 -> pressionado)
    
    @always_ff @(posedge clk) begin
        if (reset) begin
            // TODO: reset
        end else begin
            btn_prev <= btn_stable; // o sinal anterior é o anteriormente estável
            for (int i = 0; i < 3; i++) begin
                if (btn_active[i] == btn_stable[i]) begin // se não há mudança de sinal 
                    deb_cnt[i] = '0; // zera o contador
                end else begin // se há mudança de sinal
                    if (deb_cnt[i] == DEB_CYCLES-1) begin // após 20ms de mudança constante
                        btn_stable[i] <= btn_active[i]; // confirma mudança estável 
                        deb_cnt <= '0; // zera o contador
                    end else begin // enquanto não alcança a mudança
                        deb_cnt[i] <= deb_cnt[i] + 1'b1; // incrementa o contador
                    end
                end
            end
        end
    end

    assign btn_pulse = btn_stable & ~btn_prev; // btn_pulse captura apenas os posedges do sinal estável
endmodule