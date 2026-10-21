
module ALU(
    input wire OP,
    input wire [5:0] A, B,
    output wire [5:0] S
);
    assign S = (OP == 1'b0) ? (A + B) : (A - B);
endmodule