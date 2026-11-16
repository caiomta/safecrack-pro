module led_controller (
    input  logic unlocked,   
    input  logic incorrect,  
    input  logic edit_mode,
    output logic [8:0] LEDG,
    output logic [17:0] LEDR
);
    always_comb begin
        {LEDG, LEDR} = '0;
        if (edit_mode) begin
            {LEDG, LEDR} = '1;
        end else if (unlocked) begin
            LEDG = '1;
        end else if (incorrect) begin
            LEDR = '1;
        end
    end
endmodule
