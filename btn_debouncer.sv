module btn_debouncer #(
    parameter int CLK_FREQ,
    parameter int DEB_MS
) (
    input logic clk,
    input logic [3:0] btn, 
    output logic [3:0] btn_pulse 
);
    localparam int DEB_CYCLES = (CLK_FREQ >= 1000) ? (DEB_MS * CLK_FREQ / 1000) : 2;  // ciclos de clock para completar DEB_MS
    logic [3:0] btn_sync0, btn_sync1, btn_active, btn_stable, btn_prev, btn_pulse;
    logic [$clog2(DEB_CYCLES)-1:0] deb_cnt [3:0];

    // evitar metaestabilização (usuário clicando durante uma virada de clock)
    always_ff @( posedge clk ) begin
        btn_sync0 <= btn;
        btn_sync1 <= btn_sync0;
    end

    assign btn_active = ~btn_sync1;  // inverter sinal dos botões para que 1 equivala a pressionado

    // estabilizar clique para evitar ruídos mecânico esperando DEB_MS de sinal constante para confirmá-lo
    always_ff @( posedge clk ) begin
        btn_prev <= btn_stable;
        for (int i = 0; i < 4; i++) begin  // para cada botão
            if (btn_active[i] == btn_stable[i]) begin  // se o sinal atual não mudou em relação ao estável
                deb_cnt[i] <= '0;  // mantém o contador zerado
            end else begin  // caso mudou
                if (deb_cnt[i] == DEB_CYCLES-1) begin  // se o contador contou DEB_MS
                    btn_stable[i] <= btn_active[i];  // confirmar sinal estável
                    deb_cnt[i] <= '0;  // zerar contador
                end else begin  // se ainda está contando
                    deb_cnt[i] <= deb_cnt[i] + 1'b1;  // incrementar
                end
            end
        end
    end

    assign btn_pulse = btn_stable & ~btn_prev;  // detectar posedge durante o intervalo do clock atual
endmodule