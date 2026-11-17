module password_manager (
    input logic clk, save_pass,
    input logic [3:0][3:0] entered_pass,
    output logic match_pass,
    output logic [3:0][3:0] stored_pass
);
    logic [3:0][3:0] internal_pass = '0; //registra na memória interna (4 dig BCD de 4 bits cada)

    always_ff @(posedge clk) begin
		  if (save_pass) begin
            internal_pass <= entered_pass; // Grava a nova senha digitada 
        end
    end

    assign match_pass = (entered_pass == internal_pass);
    assign stored_pass = internal_pass;
endmodule