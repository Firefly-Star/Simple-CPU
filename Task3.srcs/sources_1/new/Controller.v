module InstructionFetcher
(
    input IR_Write,
    input PC_Write,
    input PC0_Write,
    input [5:0] PC_Data,
    input clk_im,
    input reset,
    
    output [5:0] PC_0,
    output reg [5:0] PC,
    output [31:0] Instruction 
);

reg [31:0] IM[63:0];
reg [5:0] PC0;
reg [31:0] IR;

always @(posedge clk_im or posedge reset)
    begin
    if (reset)
    begin
        IM[0]  = 32'h01000513;		//addi x10 x0 16      #a0=0000_0010H，数据区域（数组）首址    main
        IM[1]  = 32'h00306593;		//ori x11 x0 3        #a1=0000_0003H，累加的数据个数
        IM[2]  = 32'h03004613;		//xori x12 x0 48      #a2=0000_0030H，累加和存放的单元
        IM[3]  = 32'h002000EF;		//jal x1 2            #子程序调用
        IM[4]  = 32'h00062403;		//lw x8 0(x12)        #读出累加和
        
        IM[5]  = 32'h000502B3;		//add x5 x10 x0       #t0=数据区域首址                        BackSum
        IM[6]  = 32'h0005E333;		//or x6 x11 x0        #t1=计数器，初始为累加的数据个数
        IM[7]  = 32'h000073B3;		//and x7 x0 x0        #t2=累加和，初始清零
        
        IM[8]  = 32'h00000033;      //add x0 x0 x0        #占位符
        IM[9]  = 32'h0002AE03;		//lw x28 0(x5)        #t3=取出数据                            L
        IM[10] = 32'h01C383B3;		//add x7 x7 x28       #累加
        IM[11] = 32'h00428293;		//addi x5 x5 4        #移动数据区指针
        IM[12] = 32'hFFF30313;		//addi x6 x6 -1       #计数器-1
        IM[13] = 32'h00030163;		//beq x6 x0 2         #计数值=0，累加完成，退出循环
        IM[14] = 32'hFFBFF06F;		//jal x0 -6           #计数值≠0，继续累加，跳转至循环体首部
        
        IM[15] = 32'h00762023;		//sw x7 0(x12)        #累加和，存到指定单元                   exit
        IM[16] = 32'h00008067;		//jalr x0 x1 0        #子程序返回
    end
    else
    begin
        if(IR_Write)
        begin
            IR <= IM[PC];
        end
    end
end

always @(negedge clk_im or posedge reset)
begin
    if(reset)
    begin
        PC  <= 6'b0;
        PC0 <= 6'b0;
    end
    else
    begin
        if(PC_Write)
        begin
            PC <= PC_Data;
        end
        if(PC0_Write)
        begin
            PC0 <= PC;
        end
    end
end

assign Instruction = IR;
assign PC_0 = PC0;

endmodule

module InstructionDecoderI
(
    input [31:0] Instruction,
    output [6:0] funct7,
    output [2:0] funct3,
    output [9:0] opmask, //操作类型的掩码
    output [4:0] rs1, 
    output [4:0] rs2, 
    output [4:0] rd, 
    output [31:0] imm32
);

assign funct7 = Instruction[31:25];
assign funct3 = Instruction[14:12];
assign rs1    = Instruction[19:15];
assign rs2    = Instruction[24:20];
assign rd     = Instruction[11:7];
assign imm32  = (Instruction[6:0] == 7'b0110011)? 32'b0: //R型运算
                (Instruction[6:0] == 7'b0010011)? 
                ((funct3 == 3'b001 || funct3 == 3'b101) ? {{27{Instruction[24]}}, Instruction[24:20]} : {{20{Instruction[31]}}, Instruction[31:20]}): //I型运算
                (Instruction[6:0] == 7'b0000011)? {{20{Instruction[31]}}, Instruction[31:20]}: //I型取数
                (Instruction[6:0] == 7'b0100011)? {{20{Instruction[31]}}, Instruction[31:25], Instruction[11:7]}: //S型存数
                (Instruction[6:0] == 7'b1100011)? {{19{Instruction[31]}}, Instruction[7], Instruction[30:25], Instruction[11:8], 1'b0}: //B型分支
                (Instruction[6:0] == 7'b1100111)? {{20{Instruction[31]}}, Instruction[31:20]}: //I型转移
                (Instruction[6:0] == 7'b1101111)? {{11{Instruction[31]}}, Instruction[31], Instruction[19:12], Instruction[20], Instruction[30:21], 1'b0}: //J型转移
                (Instruction[6:0] == 7'b0110111)? {Instruction[31:12], 12'b0}: //U型lui
                (Instruction[6:0] == 7'b0010111)? {Instruction[31:12], 12'b0}: //U型auipc
                32'b0;//Default
assign opmask = (Instruction[6:0] == 7'b0110011)? 1 << 1: //R型运算
                (Instruction[6:0] == 7'b0010011)? 1 << 2: //I型运算
                (Instruction[6:0] == 7'b0000011)? 1 << 3: //I型取数
                (Instruction[6:0] == 7'b0100011)? 1 << 4: //S型存数
                (Instruction[6:0] == 7'b1100011)? 1 << 5: //B型分支
                (Instruction[6:0] == 7'b1100111)? 1 << 6: //I型转移
                (Instruction[6:0] == 7'b1101111)? 1 << 7: //J型转移
                (Instruction[6:0] == 7'b0110111)? 1 << 8: //U型lui
                (Instruction[6:0] == 7'b0010111)? 1 << 9: //U型auipc
                1 << 0;
endmodule

module CU
(
input [9:0] opmask,
input [6:0] funct7,
input [2:0] funct3,
input [3:0] FR,
input reset,
input clk,
output reg[2:0] w_data_s,
output reg SE_s,
output reg [1:0] Size_s,
output reg Mem_Write,
output reg [3:0] ALU_OP,
output reg rs2_imm_s,
output reg Reg_Write,
output reg IR_Write,
output reg PC0_Write,
output reg PC_Write,
output reg PC_s,
output reg [4:0] current_state
);

reg[4:0] next_state;

//状态机
always @(posedge clk or posedge reset)
begin
    if(reset)
    begin
        current_state <= 0;
    end
    else
    begin
        current_state <= next_state;
    end
end

//状态机变化
always @(*)
begin
    if (current_state == 0)
    begin
        next_state = 1;
    end
    else
    begin
        case(current_state)
            1:begin
                case(opmask)
                    1 << 1: next_state <= 2;
                    1 << 2: next_state <= 4;
                    1 << 3: next_state <= 5;
                    1 << 4: next_state <= 5;
                    1 << 5: next_state <= 9;
                    1 << 6: next_state <= 11;
                    1 << 7: next_state <= 11;
                    1 << 8: next_state <= 14;
                    1 << 9: next_state <= 15;
                endcase
            end
            2:begin
                case(opmask)
                    1 << 1: next_state <= 3;
                endcase
            end
            3:begin
                case(opmask)
                    1 << 1: next_state <= 1;
                    1 << 2: next_state <= 1;    
                endcase
            end
            4:begin
                case(opmask)
                    1 << 2: next_state <= 3;
                endcase
            end
            5:begin
                case(opmask)
                    1 << 3: next_state <= 6;
                    1 << 4: next_state <= 8;
                endcase
            end
            6:begin
                case(opmask)
                    1 << 3: next_state <= 7;
                endcase
            end
            7:begin
                case(opmask)
                    1 << 3: next_state <= 1;
                endcase
            end
            8:begin
                case(opmask)
                    1 << 4: next_state <= 1;
                endcase
            end
            9:begin
                case(opmask)
                    1 << 5: next_state <= 10;
                endcase
            end
            10:begin
                case(opmask)
                    1 << 5: next_state <= 1;
                endcase
            end
            11:begin
                case(opmask)
                    1 << 6: next_state <= 12;
                    1 << 7: next_state <= 13;
                endcase
            end
            12:begin 
                case(opmask)
                    1 << 6: next_state <= 16;
                endcase
            end
            13:begin
                case(opmask)
                    1 << 7: next_state <= 1;
                endcase
            end
            14:begin
                case(opmask)
                    1 << 8: next_state <= 1;
                endcase
            end
            15:begin
                case(opmask)
                    1 << 9: next_state <= 1;
                endcase
            end
            16:begin
                case(opmask)
                    1 << 6: next_state <= 1;
                endcase
            end
        endcase
    end
end
    
always @(posedge clk or posedge reset)
begin
    if (reset)
    begin
        w_data_s  <= 0;    
        SE_s      <= 0;           
        Size_s    <= 0;       
        Mem_Write <= 0;
        rs2_imm_s <= 0;          
        Reg_Write <= 0;          
        PC0_Write <= 0;          
        PC_Write  <= 0;          
        PC_s      <= 0;
    end
    else
    begin
        case(next_state)
            1:begin
                w_data_s  <= 0;    
                SE_s      <= 0;           
                Size_s    <= 0;
                Mem_Write <= 0;       
                rs2_imm_s <= 0;          
                Reg_Write <= 0;          
                PC0_Write <= 1;          
                PC_Write  <= 1;          
                PC_s      <= 0;
            end
            2:begin
                w_data_s  <= 0;    
                SE_s      <= 0;           
                Size_s    <= 0;
                Mem_Write <= 0;       
                ALU_OP    <= {funct7[5], funct3};  
                rs2_imm_s <= 0;          
                Reg_Write <= 0;          
                PC0_Write <= 0;          
                PC_Write  <= 0;          
                PC_s      <= 0;
            end
            3:begin
                w_data_s  <= 0;    
                SE_s      <= 0;           
                Size_s    <= 0;
                Mem_Write <= 0;       
                rs2_imm_s <= 0;          
                Reg_Write <= 1;          
                PC0_Write <= 0;          
                PC_Write  <= 0;          
                PC_s      <= 0;
            end
            4:begin
                w_data_s  <= 0;    
                SE_s      <= 0;           
                Size_s    <= 0;
                Mem_Write <= 0;       
                ALU_OP    <= funct3 == 3'b101 ? {funct7[5], funct3} : {1'b0, funct3};     
                rs2_imm_s <= 1;          
                Reg_Write <= 0;          
                PC0_Write <= 0;          
                PC_Write  <= 0;          
                PC_s      <= 0;
            end
            5:begin
                w_data_s  <= 0;    
                SE_s      <= 0;           
                Size_s    <= 0;
                Mem_Write <= 0;       
                ALU_OP    <= 4'b0000;       
                rs2_imm_s <= 1;          
                Reg_Write <= 0;          
                PC0_Write <= 0;          
                PC_Write  <= 0;          
                PC_s      <= 0;
            end
            6:begin
                w_data_s  <= 0;    
                SE_s      <= !funct3[2];           
                Size_s    <= funct3[1:0];
                Mem_Write <= 0;       
                rs2_imm_s <= 0;          
                Reg_Write <= 0;          
                PC0_Write <= 0;          
                PC_Write  <= 0;          
                PC_s      <= 0;
            end
            7:begin
                w_data_s  <= 2;    
                SE_s      <= 0;           
                Size_s    <= 0;
                Mem_Write <= 0;       
                rs2_imm_s <= 0;          
                Reg_Write <= 1;          
                PC0_Write <= 0;          
                PC_Write  <= 0;          
                PC_s      <= 0;
            end
            8:begin
                w_data_s  <= 0;    
                SE_s      <= 0;           
                Size_s    <= funct3[1:0];
                Mem_Write <= 1;        
                rs2_imm_s <= 0;          
                Reg_Write <= 0;          
                PC0_Write <= 0;          
                PC_Write  <= 0;          
                PC_s      <= 0;
            end
            9:begin
                w_data_s  <= 0;    
                SE_s      <= 0;           
                Size_s    <= 0;
                Mem_Write <= 0;       
                ALU_OP    <= 4'b1000;      
                rs2_imm_s <= 0;          
                Reg_Write <= 0;          
                PC0_Write <= 0;          
                PC_Write  <= 0;          
                PC_s      <= 0;
            end
            10:begin
                w_data_s  <= 0;    
                SE_s      <= 0;           
                Size_s    <= 0;
                Mem_Write <= 0;       
                rs2_imm_s <= 0;          
                Reg_Write <= 0;          
                PC0_Write <= 0;   
                if 
                ( // ZF, CF, OF, SF
                ((funct3 == 3'b000) && (FR[3] == 1))     || //beq
                ((funct3 == 3'b001) && (FR[3] == 0))     || //bne
                ((funct3 == 3'b100) && (FR[1] != FR[0])) || //blt
                ((funct3 == 3'b101) && (FR[1] == FR[0])) || //bge
                ((funct3 == 3'b110) && (FR[2] == 0))     || //bltu
                ((funct3 == 3'b111) && (FR[2] == 1))        //bgeu
                )       
                begin
                    PC_s <= 1;
                    PC_Write <= 1;
                end
            end
            11:begin
                w_data_s  <= 3;    
                SE_s      <= 0;           
                Size_s    <= 0;
                Mem_Write <= 0;       
                rs2_imm_s <= 0;          
                Reg_Write <= 1;          
                PC0_Write <= 0;          
                PC_Write  <= 0;          
                PC_s      <= 0;
            end
            12:begin
                w_data_s  <= 0;    
                SE_s      <= 0;           
                Size_s    <= 0;
                Mem_Write <= 0;       
                ALU_OP    <= 4'b0000;   
                rs2_imm_s <= 1;          
                Reg_Write <= 0;  
                PC0_Write <= 0;
                PC_Write  <= 0;          
                PC_s      <= 0;
            end
            13:begin
                w_data_s  <= 0;    
                SE_s      <= 0;           
                Size_s    <= 0;
                Mem_Write <= 0;       
                rs2_imm_s <= 0;          
                Reg_Write <= 0;          
                PC0_Write <= 0;          
                PC_Write  <= 1;          
                PC_s      <= 1;
            end
            14:begin
                w_data_s  <= 1;    
                SE_s      <= 0;           
                Size_s    <= 0;
                Mem_Write <= 0;       
                rs2_imm_s <= 0;          
                Reg_Write <= 1;          
                PC0_Write <= 0;          
                PC_Write  <= 0;          
                PC_s      <= 0;
            end
            15:begin
                w_data_s  <= 4;    
                SE_s      <= 0;           
                Size_s    <= 0;
                Mem_Write <= 0;       
                rs2_imm_s <= 0;          
                Reg_Write <= 1;          
                PC0_Write <= 0;          
                PC_Write  <= 0;          
                PC_s      <= 0;
            end
            16:begin
                w_data_s  <= 0;    
                SE_s      <= 0;           
                Size_s    <= 0;
                Mem_Write <= 0;       
                rs2_imm_s <= 0;          
                Reg_Write <= 0;          
                PC0_Write <= 0;          
                PC_Write  <= 1;          
                PC_s      <= 2; 
            end
        endcase
    end
end

always @(*)
begin
    IR_Write  = (next_state == 1);
end

endmodule