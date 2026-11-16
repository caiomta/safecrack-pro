`timescale 1ns/1ps
module tb_display_driver;
    logic [3:0][3:0] digits;
    logic [1:0] selected_digit;
    logic [3:0][6:0] digit_displays;
    logic [6:0] active_digit;
    logic clk = 0;
    logic reset, unlocked, incorrect, edit_mode;
    logic [8:0] LEDG;
    logic [17:0] LEDR;

######## frequência clock 5s and 3s only 50/30 cycles.
    localparam int TEST_FREQ = 10;
    always #5 clk = ~clk;

    display_driver display_dut (
        .digits(digits), .selected_digit(selected_digit),
        .digit_displays(digit_displays), .active_digit(active_digit)
    );
    led_controller #(.CLK_FREQ(TEST_FREQ)) led_dut (
        .clk(clk), .reset(reset), .unlocked(unlocked),
        .incorrect(incorrect), .edit_mode(edit_mode),
        .LEDG(LEDG), .LEDR(LEDR)
    );

    function automatic logic [6:0] expected(input int n);
        case (n)
            0: expected = 7'b1000000;
            1: expected = 7'b1111001;
            2: expected = 7'b0100100;
            3: expected = 7'b0110000;
            4: expected = 7'b0011001;
            5: expected = 7'b0010010;
            6: expected = 7'b0000010;
            7: expected = 7'b1111000;
            8: expected = 7'b0000000;
            9: expected = 7'b0010000;
            default: expected = 7'b1111111;
        endcase
    endfunction

    task automatic check_leds(input logic [8:0] g, input logic [17:0] r);
        if (LEDG !== g || LEDR !== r)
            $fatal(1, "LED mismatch: LEDG=%h LEDR=%h expected %h %h", LEDG, LEDR, g, r);
    endtask

    initial begin
        digits = '0;
        selected_digit = 0;
        reset = 1;
        unlocked = 0;
        incorrect = 0;
        edit_mode = 0;
        #2;
        check_leds('0, '0);
        @(negedge clk);
        reset = 0;

        for (int n = 0; n < 16; n++) begin
            for (int k = 0; k < 4; k++) digits[k] = 4'(n);
            #1;
            for (int k = 0; k < 4; k++)
                if (digit_displays[k] !== expected(n))
                    $fatal(1, "Display %0d failed for BCD %0d", k, n);
        end
        for (int k = 0; k < 4; k++) begin
            selected_digit = 2'(k);
            #1;
            if (active_digit !== expected(k+1))
                $fatal(1, "Active digit failed for index %0d", k);
        end

        edit_mode = 1;
        #1;
        check_leds('1, '1);
        @(negedge clk);
        edit_mode = 0;
        #1;
        check_leds('0, '0);


        unlocked = 1;
        @(posedge clk);
        #1;
        check_leds('1, '0);
        @(negedge clk);
        unlocked = 0;
        repeat (49) @(posedge clk);
        #1;
        check_leds('1, '0);
        @(posedge clk);
        #1;
        check_leds('0, '0);


        @(negedge clk);
        incorrect = 1;
        @(posedge clk);
        #1;
        check_leds('0, '1);
        @(negedge clk);
        incorrect = 0;
        repeat (29) @(posedge clk);
        #1;
        check_leds('0, '1);
        @(posedge clk);
        #1;
        check_leds('0, '0);

        $display("PASS: all display and LED checks completed.");
        $finish;
    end
endmodule
