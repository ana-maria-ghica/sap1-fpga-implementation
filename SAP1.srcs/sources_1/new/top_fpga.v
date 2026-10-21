`timescale 1ns / 1ps

module top_fpga(
    input  wire        clk_100mhz,  // Pinul E3 de pe plac?
    input  wire        btn_reset,   // Buton pentru reset (ex: BTNC)
    output wire [7:0]  an,          // Anozii display-ului (activi pe 0)
    output wire [6:0]  seg          // Catozii CA-CG (activi pe 0)
);
    // divizor de ceas
    reg [31:0] clk_div_cnt = 32'd0;
    reg        clk_1hz     = 1'b0;

    always @(posedge clk_100mhz) begin
        if (btn_reset) begin
            clk_div_cnt <= 32'd0;
            clk_1hz     <= 1'b0;
        end else if (clk_div_cnt == 32'd49_999_999) begin
            clk_div_cnt <= 32'd0;
            clk_1hz     <= ~clk_1hz;
        end else begin
            clk_div_cnt <= clk_div_cnt + 32'd1;
        end
    end

    // instantiere SAP1
    wire [5:0] acc_val;

    CPU cpu_inst (
        .clk(clk_1hz),
        .reset(btn_reset),
        .acc(acc_val)
    );

    // modulul de refresh pt afisaj
    reg [19:0] refresh_cnt = 20'd0;
    always @(posedge clk_100mhz) begin
        refresh_cnt <= refresh_cnt + 20'd1;
    end

    // folosesc primul bit de selectie pentru a comuta intre digit 0 si digit 1
    wire digit_sel = refresh_cnt[18];

   
    // impartim 6 biti din acumulator in 2 cifre hexazecimale
    // acc_val[3:0] pt unitati, {2'b00, acc_val[5:4]} pt zecile
    reg [3:0] current_nibble;
    reg [7:0] an_reg;

    always @(*) begin
        if (digit_sel == 1'b0) begin
            an_reg         = 8'b1111_1110;
            current_nibble = acc_val[3:0];
        end else begin
            an_reg         = 8'b1111_1101;
            current_nibble = {2'b00, acc_val[5:4]};
        end
    end

    assign an = an_reg;

    // decodificator hexazecimal - 7 segmente activ pe 0
    // segmente: {CA, CB, CC, CD, CE, CF, CG}
    reg [6:0] seg_reg;
    always @(*) begin
        case (current_nibble)
            4'h0: seg_reg = 7'b0000001;
            4'h1: seg_reg = 7'b1001111;
            4'h2: seg_reg = 7'b0010010;
            4'h3: seg_reg = 7'b0000110;
            4'h4: seg_reg = 7'b1001100;
            4'h5: seg_reg = 7'b0100100;
            4'h6: seg_reg = 7'b0100000;
            4'h7: seg_reg = 7'b0001111;
            4'h8: seg_reg = 7'b0000000;
            4'h9: seg_reg = 7'b0000100;
            4'hA: seg_reg = 7'b0001000;
            4'hB: seg_reg = 7'b1100000;
            4'hC: seg_reg = 7'b0110001;
            4'hD: seg_reg = 7'b1000010;
            4'hE: seg_reg = 7'b0110000;
            4'hF: seg_reg = 7'b0111000;
            default: seg_reg = 7'b1111111;
        endcase
    end

    assign seg = seg_reg;

endmodule