module ACCUMULATOR(
    input wire clk,
    input wire reset,
    input wire enable,
    input wire [5:0] data_in,
    output reg [5:0] data_out
);
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            data_out <= 6'b000000;
        end else if (enable) begin
            data_out <= data_in;
        end
    end
endmodule

