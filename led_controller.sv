module led_controller (
    input  logic unlocked,   
    input  logic incorrect,  
    input  logic edit_mode,
    output logic [8:0] ledg,
    output logic [17:0] ledr
);
    always_comb begin
        {ledg, ledr} = '0;
        if (edit_mode) begin
            {ledg, ledr} = '1;
        end else if (unlocked) begin
            ledg = '1;
        end else if (incorrect) begin
            ledr = '1;
        end
    end
endmodule
