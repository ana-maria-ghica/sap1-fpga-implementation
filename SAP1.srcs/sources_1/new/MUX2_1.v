module MUX2_1(
    input wire SEL,
    input wire [5:0] A,
    input wire [5:0] B,
    output wire [5:0] C
);
    assign C = (SEL == 1'b1) ? B : A;
endmodule