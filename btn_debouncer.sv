module btn_debouncer #(
    parameter int CLK_FREQ = 50_000_000,
    parameter int DEB_MS = 20
) (
    input logic clk,
    input logic [3:0] btn,
    output logic [3:0] btn_pulse
);
    localparam int DEB_CYCLES = (CLK_FREQ >= 1000) ? (DEB_MS * CLK_FREQ / 1000) : 2;
    logic [3:0] btn_sync0, btn_sync1, btn_active, btn_stable, btn_prev, btn_pulse;
    logic [$clog2(DEB_CYCLES)-1:0] deb_cnt [3:0];

    always_ff @( posedge clk ) begin
        btn_sync0 <= btn;
        btn_sync1 <= btn_sync0;
    end

    assign btn_active = ~btn_sync1;

    always_ff @( posedge clk ) begin
        btn_prev <= btn_stable;
        for (int i = 0; i < 4; i++) begin
            if (btn_active[i] == btn_stable[i]) begin
                deb_cnt[i] <= '0;
            end else begin
                if (deb_cnt[i] == DEB_CYCLES-1) begin
                    btn_stable[i] <= btn_active[i];
                    deb_cnt[i] <= '0;
                end else begin
                    deb_cnt[i] <= deb_cnt[i] + 1'b1;
                end
            end
        end
    end

    assign btn_pulse = btn_stable & ~btn_prev;
endmodule