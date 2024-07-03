取指令 
1
m0: d:PC_write = 1, PC_s = 0, IR_Write = 1, PC0_write = 1

R型运算 1 << 1
2  
m1: d:rs2_imm_s = 0, ALU_OP = aluop
3
m2: d:w_data_s = 0, Reg_write = 1

I型运算 1 << 2
4
m1: d:rs2_imm_s = 1, ALU_OP = aluop
3
m2: d:w_data_s = 0, Reg_write = 1

I型取数 1 << 3
5
m1: d:rs2_imm_s = 1, ALUOP = add
6
m2: d:Size_s = size, SE_s = isSignedExtension
7
m3: d:w_data_s = 2, Reg_write = 1

S型存数 1 << 4
5
m1: d:rs2_imm_s = 1, ALUOP = add
8
m2: d:Mem_write = 1, Size_s = size

B型分支 1 << 5
9 
m1: d:rs2_imm_s = 0, ALUOP = sub
10
m2: d:if f(FR):
       PC_s = 1, PC_write = 1

I型转移 1 << 6
11
m1: d:w_data_s = 3, Reg_write = 1
12
m2: d:rs2_imm_s = 1, ALUOP = add
16
m3: d: PC_s = 2, PC_write = 1

J型转移 1 << 7
11
m1: d:w_data_s = 3, Reg_write = 1
13
m2: d:PC_s = 1, PC_write = 1

U型lui 1 << 8
14
m1: d:w_data_s = 1, Reg_write = 1

U型auipc 1 << 9
15
m1: d:w_data_s = 4, Reg_write = 1



beq:000, bne:001, blt:100, bge:101, bltu:110, bgeu:111