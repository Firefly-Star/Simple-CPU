module DM//数据存储器
(
    input [31:0] M_W_Data,
    input [7:0] DM_Addr,
    input clk_dm,
    input SE_s, //0:零扩展， 1：符号扩展
    input [1:0] Size_s,//00:按字节访问， 01：按半字访问， 1x:按字访问
    input Mem_Write,
    input rst,
    output reg [31:0] M_R_Data
);

reg [7:0] mem[255:0];
integer i;
always @(posedge clk_dm or posedge rst)
begin
    if (rst)
    begin
        for (i = 0;i <= 255;i = i + 1)
        begin
            mem[i] <= i;
        end
    end
    else
    begin
        if (Mem_Write)//写入
        begin
            if (Size_s == 2'b00)//sb
            begin
                mem[DM_Addr] <= M_W_Data[7:0];
            end
            if (Size_s == 2'b01)//sh
            begin
                mem[DM_Addr] <= M_W_Data[7:0];
                mem[DM_Addr + 1] <= M_W_Data[15:8];
            end
            if (Size_s == 2'b10 || Size_s == 2'b11)//sw
            begin
                mem[DM_Addr] <= M_W_Data[7:0];
                mem[DM_Addr + 1] <= M_W_Data[15:8];
                mem[DM_Addr + 2] <= M_W_Data[23:16];
                mem[DM_Addr + 3] <= M_W_Data[31:24];
            end
        end
        else//读出
        begin
            if (Size_s == 2'b00)//lb
            begin
                if (!SE_s)
                begin//零扩展
                    M_R_Data <= {24'b0, mem[DM_Addr]};
                end
                else
                begin//符号扩展
                    M_R_Data <= { {24{mem[DM_Addr][7]}} , mem[DM_Addr]};
                end
            end
            if (Size_s == 2'b01)//lh
            begin
                if (!SE_s)
                begin//零扩展
                    M_R_Data <= {16'b0, mem[DM_Addr + 1], mem[DM_Addr]};
                end
                else
                begin//符号扩展
                    M_R_Data <= { {16{mem[DM_Addr + 1][7]}} , mem[DM_Addr + 1], mem[DM_Addr]};
                end
            end
            if (Size_s == 2'b10 || Size_s == 2'b11)//lw
            begin
                M_R_Data <= {mem[DM_Addr + 3], mem[DM_Addr + 2], mem[DM_Addr + 1], mem[DM_Addr]};
            end
        end
    end
end

endmodule