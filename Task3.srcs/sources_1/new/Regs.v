module Regs//¼Ä´æÆ÷¶Ñ
(
    input clk_Regs,
    input Reg_Write,
    input [31:0] W_data,
    input [4:0] R_Addr_A,
    input [4:0] R_Addr_B,
    input [4:0] W_Addr,
    input rst,
    output [31:0] R_Data_A,
    output [31:0] R_Data_B
);

    reg [31:0] regs[31:0];
    integer i;
    always @(posedge clk_Regs or posedge rst)
    begin
        if (rst)//ÖØÖÃ
        begin
            for (i = 0;i <= 31;i = i + 1)
            begin
                regs[i] <= 32'b0;
            end
        end
        else
        if (Reg_Write && W_Addr != 0)
        begin
            regs[W_Addr] <= W_data;
        end
    end

    //¶Á³ö
    assign R_Data_A = regs[R_Addr_A];
    assign R_Data_B = regs[R_Addr_B];

endmodule

