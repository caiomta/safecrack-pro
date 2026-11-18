module input_handler #(
    parameter int CLK_FREQ = 50_000_000
) (
    input logic clk, rstn,
	 input logic [2:0] keys,
    output logic [3:0] digit_val,  // valor do dígito atualmente selecionado
    output logic confirm_pulse  // pulso ao confirmar
);
    logic [2:0] btn_pulse;

    // debouncing dos botões de movimentação e confirmação
    genvar i;
    generate
        for (i = 0; i < 3; i++) begin : gen_deb
            btn_debouncer #(
                .CLK_FREQ(CLK_FREQ)
            ) deb (
                .clk(clk),
                .rstn(rstn),
                .btn(keys[i]),
                .btn_pulse(btn_pulse[i])
            );
        end
    endgenerate
	
    assign confirm_pulse = btn_pulse[0];

    always_ff @(posedge clk or negedge rstn) begin
		  if (!rstn) begin
		      digit_val <= '0;
        end else if (confirm_pulse) begin  // reinicialização durante reset ou confirmação
            digit_val <= '0;
        end else if (btn_pulse[1]) begin  // incrementação
				if (digit_val == 4'd9) digit_val <= '0;
				else digit_val <= digit_val + 1'b1;
        end else if (btn_pulse[2]) begin  // decrementação
            if (digit_val <= '0) digit_val <= 4'd9;
				else digit_val <= digit_val - 1'b1;
        end
    end
endmodule