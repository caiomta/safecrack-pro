module timer_counter #(
    parameter int CLK_FREQ
) (
    input logic clk, rstn, timer_enable, timer_mode,  // 0: 3s, 1: 5s 
    output logic timer_done
);
    int timer_cycles;
    assign timer_cycles = (timer_mode) ? 5 * CLK_FREQ : 3 * CLK_FREQ;
    logic [$clog2(5 * CLK_FREQ)-1:0] cnt;

    always_ff @( posedge clk or negedge rstn ) begin 
        if (!(rstn && timer_enable)) begin
            cnt <= 0;
            timer_done <= 1'b0;
        end else begin
            if (cnt >= timer_cycles-1) begin
                cnt <= 0;
                timer_done <= 1'b1;
            end else begin
                cnt <= cnt + 1;
                timer_done <= 1'b0;
            end
        end
    end
endmodule