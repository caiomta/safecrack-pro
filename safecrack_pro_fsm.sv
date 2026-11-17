module safecrack_pro_fsm (
    input logic clk, rstn, confirm_pulse, match_pass, timer_done,
    output logic save_digit, save_pass, unlocked, incorrect, edit_mode,
    output logic [1:0] selected_digit,
	 output logic [3:0][3:0] entered_pass
);
    typedef enum logic [3:0] {
        EDIT1, EDIT2, EDIT3, EDIT4,
        VALIDATE,
        UNLOCKED,
        INCORRECT,
        NEW_PASS1, NEW_PASS2, NEW_PASS3, NEW_PASS4,
        SAVE_PASS
    } state_t;

    state_t current_state, next_state;

    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) current_state <= EDIT1;
        else current_state <= next_state;
    end

    always_comb begin
        next_state = current_state;
        {selected_digit, save_digit, save_pass, unlocked, incorrect, edit_mode} = '0;
        
        case (current_state)
            EDIT1: begin
                selected_digit = 2'd0;
					 entered_pass = '0;
                if (confirm_pulse) begin
                    save_digit = '1;
                    next_state = EDIT2;
                end
            end

            EDIT2: begin
                selected_digit = 2'd1;
                if (confirm_pulse) begin
                    save_digit = '1;
                    next_state = EDIT3;
                end
            end

            EDIT3: begin
                selected_digit = 2'd2;
                if (confirm_pulse) begin
                    save_digit = '1;
                    next_state = EDIT4;
                end
            end

            EDIT4: begin
                selected_digit = 2'd3;
                if (confirm_pulse) begin
                    save_digit = '1;
                    next_state = VALIDATE;
                end
            end

            VALIDATE: next_state = match_pass ? UNLOCKED : INCORRECT;

            UNLOCKED: begin
                unlocked = '1;
                if (confirm_pulse) next_state = NEW_PASS1;
                else if (timer_done) next_state = EDIT1;
            end

            INCORRECT: begin
                incorrect = '1;
                if (timer_done) next_state = EDIT1;
            end

            NEW_PASS1: begin
                selected_digit = 2'd0;
                edit_mode = '1;
                if (confirm_pulse) begin
                    save_digit = '1;
                    next_state = NEW_PASS2;
                end
            end

            NEW_PASS2: begin
                selected_digit = 2'd1;
                edit_mode = '1;
                if (confirm_pulse) begin
                    save_digit = '1;
                    next_state = NEW_PASS3;
                end
            end

            NEW_PASS3: begin
                selected_digit = 2'd2;
                edit_mode = '1;
                if (confirm_pulse) begin
                    save_digit = '1;
                    next_state = NEW_PASS4;
                end
            end

            NEW_PASS4: begin
                selected_digit = 2'd3;
                edit_mode = '1;
                if (confirm_pulse) begin
                    save_digit = '1;
                    next_state = SAVE_PASS;
                end
            end

            SAVE_PASS: begin
                {edit_mode, save_pass} = '1;
                next_state = EDIT1;
            end

            default: next_state = EDIT1;
        endcase
    end
endmodule