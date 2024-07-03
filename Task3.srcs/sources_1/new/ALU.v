module ALU//ALU模块
(
    input [31:0] a_input,
    input [31:0] b_input,
    input [3:0] alu_op,
    input clk_alu,
    output reg [31:0] F,
    output reg [3:0] FR// ZF, CF, OF, SF
);

reg [31:0] A;
reg [31:0] B;
reg C32;
reg ZF, CF, OF, SF;
reg [31:0]F_temp;

always @(*)
begin
    A <= a_input;
    B <= b_input;
    
    case(alu_op)
    4'b0000://加法
    begin
        {C32, F_temp} = A + B;
        CF = C32;
        OF = A[31] ^ B[31] ^ F_temp[31] ^ C32;
    end
    4'b0001://左移
    begin
        F_temp = A << B;
    end
    4'b0011://无符号比较小于置数
    begin
        F_temp = ($unsigned(A) < $unsigned(B))? 1:0;
    end
    4'b0010://有符号数比较小于置数
    begin
        F_temp = ($signed(A) < $signed(B))? 1:0;
    end
    4'b0100://异或
    begin
        F_temp = A ^ B;
    end
    4'b0101://逻辑右移
    begin
        F_temp = A >> B;
    end
    4'b0110://按位或
    begin
        F_temp = A | B;
    end
    4'b0111://按位与
    begin
        F_temp = A & B;
    end
    4'b1000://减法
    begin
        {C32, F_temp} = A - B;
        CF = !C32;
        OF = A[31] ^ B[31] ^ F_temp[31] ^ C32;
    end
    4'b1101://算术右移
    begin
        F_temp = $signed(A) >>> $signed(B);
    end
    endcase
    
    ZF = F_temp==0;
    SF = F_temp[31];
    

end

always @(posedge clk_alu)
begin
    F = F_temp;
    FR = {ZF, CF, OF, SF};
end


endmodule