module PC(
    input wire clk,
    input wire reset,
    input wire enable,
    output reg [7:0] pointer
);
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            pointer <= 8'h00;
        end else if (enable) begin
            pointer <= pointer + 1'b1;
        end
    end
endmodule