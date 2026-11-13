module timer_counter #(
    parameter int CLK_FREQ
) (
    input logic clk, rstn, timer_enable, timer_mode,  // 0: 3s, 1: 5s 
    output logic timer_done  // pulso ao terminar contagem
);
    int timer_cycles; 
    assign timer_cycles = (timer_mode) ? 5 * CLK_FREQ : 3 * CLK_FREQ;
    logic [$clog2(5 * CLK_FREQ)-1:0] cnt;

    always_ff @( posedge clk or negedge rstn ) begin 
        if (!(rstn && timer_enable)) begin  // reinicialização ao resetar ou desativar timer
            cnt <= 0;
            timer_done <= 1'b0;
        end else begin
            if (cnt >= timer_cycles-1) begin  // ao completar contagem
                timer_done <= 1'b1;  // lançar pulso de término
            end else begin  // enquanto não completa
                cnt <= cnt + 1;  // incrementa contador
                timer_done <= 1'b0;
            end
        end
    end
endmodule