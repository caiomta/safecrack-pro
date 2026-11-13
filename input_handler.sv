module input_handler #(
    parameter int CLK_FREQ
) (
    input logic clk, rstn, prev_btn, next_btn, confirm_btn,
    output logic [3:0] digit_val,
    output logic confirm_pulse
);
    logic [2:0] deb_btn;
    assign deb_btn = {prev_btn, next_btn, confirm_btn};
    logic [2:0] btn_pulse;

    genvar i;
    generate
        for (i = 0; i < 3; i++) begin : gen_deb
            btn_debouncer #(
                .CLK_FREQ(CLK_FREQ)
            ) deb (
                .clk(clk),
                .rstn(rstn),
                .btn(deb_btn[i]),
                .btn_pulse(btn_pulse[i])
            );
        end
    endgenerate

    logic prev_pulse, next_pulse;
    assign {prev_pulse, next_pulse, confirm_pulse} = btn_pulse;

    always_ff @( posedge clk || negedge rstn ) begin
        if (!rstn or confirm_pulse) begin
            digit_val <= 4'd0;
        end else if (next_pulse) begin
            digit_val <= (digit_val == 4'd9) ? 4'd0 : digit_val + 1'b1;
        end else if (prev_pulse) begin
            digit_val <= (digit_val == 4'd0) ? 4'd9 : digit_val - 1'b1;
        end
    end
endmodule