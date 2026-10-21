module DECODER(
    input  wire [7:0] instr,
    output wire OP,
    output wire LOAD_ACC,
    output wire OUT_ACC,
    output wire [5:0] A,
    output wire [5:0] B,
    output wire HALT
);
    assign LOAD_ACC = (instr[7:6] == 2'b00);
    assign OP = instr[7];
    assign OUT_ACC = (instr == 8'b11000000);
    assign HALT = (instr == 8'b11111111);

    assign A = (instr[7:6] == 2'b00) ? instr[5:0] : 6'b000000;
    assign B = (instr[7:6] == 2'b01 || instr[7:6] == 2'b10) ? instr[5:0] : 6'b000000;
endmodule