module safecrack_pro_fsm (
    input logic clk, reset,
    input logic [2:0] btn, // botões de escolha e confirmação
    output logic [3:0] [6:0] digit_displays, // 4 displays de 7 leds
    output logic [6:0] active_digit, // display de 7 leds para indicar o dígito
                                     // sendo modificado no momento
    output logic unlocked, incorrect // leds informativos de estado
);

endmodule