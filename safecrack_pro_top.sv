module safecrack_pro_top #(
    parameter int CLK_FREQ = 50_000_000 
) (
    input logic clk,
    input logic [3:0] keys,
    output logic [3:0][6:0] digit_displays,
    output logic [6:0] active_display,
    output logic [8:0] ledg,
    output logic [17:0] ledr
);
    logic rstn;
    assign rstn = keys[0];

    logic confirm_pulse, save_digit, save_pass, unlocked, incorrect, edit_mode,
          match_pass, timer_done, timer_mode;
    logic [1:0] selected_digit, digit_index;
    logic [3:0] digit_val;
    logic [3:0][3:0] entered_pass, stored_pass, display_digits;
	 
	 assign digit_index = 2'd3 - selected_digit;

    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) entered_pass <= '0;  // resetar todos
		  else if (unlocked || incorrect || save_pass) entered_pass <= '0;
        else if (save_digit) entered_pass[digit_index] <= digit_val;  // salvar o dígito confirmado
    end

    always_comb begin
	     display_digits = entered_pass;
        display_digits[digit_index] = digit_val;  // exibir dígito sendo modificado na sua posição
    end

    assign timer_mode = unlocked;  // locked (0) -> 3s; unlocked (1) -> 5s

    // tratamento de entradas
    input_handler #(
        .CLK_FREQ(CLK_FREQ)
    ) u_input_handler (
        .clk(clk),
		  .rstn(rstn),
        .keys(keys[3:1]),
        .digit_val(digit_val),
        .confirm_pulse(confirm_pulse)
    );

    // máquina de estados finita
    safecrack_pro_fsm u_fsm (
        .clk(clk),
        .rstn(rstn),
        .confirm_pulse(confirm_pulse),
        .match_pass(match_pass),
        .timer_done(timer_done),
        .save_digit(save_digit),
        .save_pass(save_pass),
        .unlocked(unlocked),
        .incorrect(incorrect),
        .edit_mode(edit_mode),
        .selected_digit(selected_digit)
    );

    // gerenciador/checador de senha
    password_manager u_password_manager (
        .clk(clk),
        .entered_pass(entered_pass),
        .save_pass(save_pass),
        .match_pass(match_pass),
        .stored_pass(stored_pass)
    );

    // contador
    timer_counter #(
        .CLK_FREQ(CLK_FREQ)
    ) u_counter (
        .clk(clk),
        .rstn(rstn),
        .timer_enable(unlocked | incorrect),  // ativa contador se desbloqueado ou senha incorreta
        .timer_mode(timer_mode),
        .timer_done(timer_done)
    );

    // controlador de leds
    led_controller u_led_controller (
        .unlocked(unlocked),
        .incorrect(incorrect),
        .edit_mode(edit_mode),
        .ledg(ledg),
        .ledr(ledr)
    );

    // conversor de valores para o display
    display_driver u_display_driver (
        .digits(display_digits),
        .selected_digit(selected_digit),
        .digit_displays(digit_displays),
        .active_display(active_display)
    );
endmodule