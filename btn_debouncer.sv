module btn_debouncer #(
    parameter int CLK_FREQ,
    parameter int DEB_MS = 20
) (
    input logic clk,
    input logic rstn,
    input logic btn, 
    output logic btn_pulse 
);
    localparam int DEB_CYCLES = (CLK_FREQ >= 1000) ? (DEB_MS * CLK_FREQ / 1000) : 2;  // ciclos de clock para completar DEB_MS
    logic btn_sync0, btn_sync1, btn_active, btn_stable, btn_prev;
    logic [$clog2(DEB_CYCLES)-1:0] deb_cnt;

    // evitar metaestabilização (usuário clicando durante uma virada de clock)
    always_ff @( posedge clk or negedge rstn ) begin
        if (!rstn) begin  // reinicialização durante reset
            btn_sync0 <= 1'b1;
            btn_sync1 <= 1'b1;
        end else begin
            btn_sync0 <= btn;
            btn_sync1 <= btn_sync0;
        end
    end

    assign btn_active = !btn_sync1;  // inverter sinal do botão para que 1 equivala a pressionado

    // estabilizar clique para evitar ruídos mecânico esperando DEB_MS de sinal constante para confirmá-lo
    always_ff @( posedge clk or negedge rstn ) begin
        if (!rstn) begin  // reinicialização durante reset
            btn_stable <= 1'b0;
            btn_prev <= 1'b0;
            deb_cnt <= 1'b0;
        end else begin  
            btn_prev <= btn_stable;
            if (btn_active == btn_stable) begin  // se o sinal atual não mudou em relação ao estável
                deb_cnt <= '0;  // mantém o contador zerado
            end else begin  // caso mudou
                if (deb_cnt == DEB_CYCLES-1) begin  // se o contador contou DEB_MS
                    btn_stable <= btn_active[i];  // confirmar sinal estável
                    deb_cnt <= '0;  // zerar contador
                end else begin  // se ainda está contando
                    deb_cnt <= deb_cnt + 1'b1;  // incrementar
                end
            end
        end
    end

    assign btn_pulse = btn_stable & !btn_prev;  // detectar posedge durante o intervalo do clock atual
endmodule