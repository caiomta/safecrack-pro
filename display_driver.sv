module display_driver (
    input  logic [3:0][3:0] digits,
    input  logic [1:0] selected_digit,
    output logic [3:0][6:0] digit_displays,
    output logic [6:0] active_digit
);
    function automatic logic [6:0] decode(input logic [3:0] value);
        case (value)
            4'd0: decode = 7'b1000000;
            4'd1: decode = 7'b1111001;
            4'd2: decode = 7'b0100100;
            4'd3: decode = 7'b0110000;
            4'd4: decode = 7'b0011001;
            4'd5: decode = 7'b0010010;
            4'd6: decode = 7'b0000010;
            4'd7: decode = 7'b1111000;
            4'd8: decode = 7'b0000000;
            4'd9: decode = 7'b0010000;
            default: decode = 7'b1111111; // blank invalid BCD
        endcase
    endfunction

    always_comb begin
        for (int i = 0; i < 4; i++)
            digit_displays[i] = decode(digits[i]);
        active_digit = decode({2'b00, selected_digit} + 4'd1);
    end
endmodule
