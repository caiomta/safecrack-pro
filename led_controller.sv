module led_controller #(
    parameter int CLK_FREQ = 50_000_000) 
(
    input  logic clk,
    input  logic reset,
    input  logic unlocked,   // one-clock event pulse
    input  logic incorrect,  // one-clock event pulse
    input  logic edit_mode,
    output logic [8:0] LEDG,
    output logic [17:0] LEDR
);
    localparam int SUCCESS_CYCLES = 5 * CLK_FREQ;
    localparam int ERROR_CYCLES   = 3 * CLK_FREQ;
    localparam int MAX_CYCLES = (SUCCESS_CYCLES > ERROR_CYCLES)
                              ? SUCCESS_CYCLES : ERROR_CYCLES;
    localparam int COUNT_W = (MAX_CYCLES > 1) ? $clog2(MAX_CYCLES) : 1;

    typedef enum logic [1:0] {IDLE, SUCCESS, FAILURE} state_t;
    state_t state;
    logic [COUNT_W-1:0] count;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            count <= '0;
        end else if (edit_mode) begin
            state <= IDLE;
            count <= '0;
        end else if (incorrect) begin // error takes priority if simultaneous
            state <= FAILURE;
            count <= '0;
        end else if (unlocked) begin
            state <= SUCCESS;
            count <= '0;
        end else begin
            case (state)
                SUCCESS: if (count == SUCCESS_CYCLES - 1) begin
                    state <= IDLE;
                    count <= '0;
                end else count <= count + 1'b1;
                FAILURE: if (count == ERROR_CYCLES - 1) begin
                    state <= IDLE;
                    count <= '0;
                end else count <= count + 1'b1;
                default: begin
                    state <= IDLE;
                    count <= '0;
                end
            endcase
        end
    end

    always_comb begin
        LEDG = '0;
        LEDR = '0;
        if (edit_mode) begin
            LEDG = '1;
            LEDR = '1;
        end else if (state == SUCCESS) begin
            LEDG = '1;
        end else if (state == FAILURE) begin
            LEDR = '1;
        end
    end
endmodule
