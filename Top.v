module top //ALU Top
(
    input [31:0] sw,
    input [6:1] swb,
    input clk,//数码管用的时钟源
    output enable,
    output [2:0] which,
    output [7:0] seg
);

wire [31:0] data_in;
reg [31:0] data_a;
reg [31:0] data_b;

wire [3:0] alu_op;
wire [1:0] out_select;

wire [31:0] result;
wire [3:0] flag;

wire save_a, save_b, rst;

assign data_in = sw[31:0];
assign alu_op = sw[31:28];
assign out_select = sw[1:0];

assign save_a = swb[6];
assign save_b = swb[5];
assign rst = swb[4];

reg [31:0] data_out;

always @(posedge save_a)
begin
    data_a = data_in;
end

always @(posedge save_b)
begin
   data_b = data_in;
end

always @(*)
begin
    case(out_select)
    2'b00: data_out = result;
    2'b01: data_out = {28'b0, flag};
    2'b10: data_out = data_a;
    2'b11: data_out = data_b;
    endcase
end

ALU m_ALU
(
.a_input(data_a),
.b_input(data_b),
.alu_op(alu_op),
.rst(rst),
.F(result),
.FR(flag)
);

Display display
(
.clk(clk),                  //时钟源20MHz
.rst(rst),                  //复位信号
.data(data_out),          //32位待显示数据
.enable(enable),              //数码管显示使能，=1，某个（which指定）数码管点亮，=0，全灭
.which(which),     //片选编码（驱动哪一位数码管点亮）
.seg(seg)        // 段选信号（点亮哪些段，以显示字形）
);

endmodule

//-------------------------------------------------------------------

module top // Regs Top
(
   input [31:0] sw,
   input [6:1] swb,
   input clk,
   output [2:0] which,
   output [7:0] seg,
   output enable
);

wire clk_cpu;
wire rst;
wire clk_temp;
wire Reg_Write;

assign clk_cpu = swb[6];
assign clk_temp = swb[4];
assign rst = swb[5];
assign Reg_Write = swb[3];

reg [31:0] temp;

wire [31:0] rs1_data;
wire [31:0] rs2_data;

wire [1:0] display_select;

assign display_select = sw[1:0];

always @(posedge clk_temp)
begin
    temp <= sw[31:0];
end

Regs m_Regs
(
.clk_Regs(!clk_cpu),         
.Reg_Write(Reg_Write),
.W_data(temp), 
.R_Addr_A(sw[31:27]),   
.R_Addr_B(sw[26:22]),   
.W_Addr(sw[21:17]),     
.rst(rst),              
.R_Data_A(rs1_data), 
.R_Data_B(rs2_data)  
);

Display m_Display
(
.clk(clk),             
.rst(rst),             
.data(display_select == 2'b00 ? sw[31:27] : 
      display_select == 2'b01 ? sw[26:22] : 
      display_select == 2'b10 ? rs1_data :
      rs2_data),     
.enable(enable),         
.which(which),
.seg(seg)   
);

endmodule

//-------------------------------------------------------------------

module top //Mem Top
(
   input [31:0] sw,
   input [6:1] swb,
   input clk,//数码管用的时钟源
   output enable,
   output [2:0] which,
   output [7:0] seg
);

wire clk_dm;
wire SE_s;
wire mem_write;
wire rst;
wire save;
wire [31:0] data_in;
wire [1:0] Size_s;
wire [7:0] DM_Addr;
wire [31:0] M_R_Data;

assign clk_dm = swb[6];//总控
assign mem_write = swb[4];//控制写入
assign rst = swb[3];//清空
assign save = swb[2];//写入暂存器
assign data_in = sw;
assign Size_s = sw[31:30];//控制长度，00：字节，01：半字，1x：字
assign DM_Addr = sw[29:22];//控制地址
assign SE_s = sw[21];//扩展方式

reg [31:0] temp;

always @(posedge save)
begin
   temp <= sw;
end

DM dm
(
   .M_W_Data(temp),
   .DM_Addr(DM_Addr),
   .clk_dm(clk_dm),
   .SE_s(SE_s), //0:零扩展， 1：符号扩展
   .Size_s(Size_s),//00:按字节访问， 01：按半字访问， 1x:按字访问
   .Mem_Write(mem_write),
   .rst(rst),
   .M_R_Data(M_R_Data)
);

Display display
(
   .clk(clk),                  //时钟源20MHz
   .rst(rst),                  //复位信号
   .data(M_R_Data),          //32位待显示数据
   .enable(enable),              //数码管显示使能，=1，某个（which指定）数码管点亮，=0，全灭
   .which(which),     //片选编码（驱动哪一位数码管点亮）
   .seg(seg)        // 段选信号（点亮哪些段，以显示字形）
);

endmodule

//-----------------------------------------------------------------

module top // InstructionFetcher Top
(
   input [31:0] sw,
   input [6:1] swb,
   input clk,
   output [2:0] which,
   output [7:0] seg,
   output enable
);

wire clk_cpu;
wire PC_write;
wire PC0_write;
reg[5:0] PC_data_in;
wire IR_write;
wire rst;
wire [5:0] PC0_data_out;
wire [5:0] PC_data_out;
wire [31:0] Instruction;
wire PC_in_select;

wire data_display;

assign clk_cpu = swb[6];
assign PC_write = swb[5];
assign PC0_write = swb[4];
assign IR_write = swb[3];
assign rst = swb[2];
assign PC_in_select = sw[31];
assign data_display = sw[0];

always @(*)
begin
    PC_data_in = 6'b100000;
end

InstructionFetcher m_InstructionFecher
(
.IR_Write(1),
.PC_Write(1),
.PC0_Write(1),
.PC_Data(PC_in_select == 0 ? PC_data_out + 4 : PC_data_in),
.clk_im(clk_cpu),
.reset(rst),
.PC_0(PC0_data_out),
.PC(PC_data_out),
.Instruction(Instruction) 
);

Display m_Display
(
.clk(clk),             
.rst(rst),             
.data(data_display == 0 ? Instruction : {26'b0, PC_data_out}),     
.enable(enable),         
.which(which),
.seg(seg)   
);

endmodule

//-----------------------------------------------------------------------

module top // InstructionDocoder Top
(
   input [31:0] sw,
   input [6:1] swb,
   input clk,
   output [2:0] which,
   output [7:0] seg,
   output enable
);

wire clk_cpu;
wire PC_write;
wire PC0_write;
reg[5:0] PC_data_in;
wire IR_write;
wire rst;
wire [5:0] PC0_data_out;
wire [5:0] PC_data_out;
wire [31:0] Instruction;
wire PC_in_select;

wire [2:0] data_display;
wire [6:0] funct7;
wire [2:0] funct3;
wire [9:0] opmask;
wire [4:0] rs1, rs2, rd;
wire [31:0] imm32;

assign clk_cpu = swb[6];
assign PC_write = swb[5];
assign PC0_write = swb[4];
assign IR_write = swb[3];
assign rst = swb[2];
assign PC_in_select = sw[31];
assign data_display = sw[2:0];

always @(*)
begin
    PC_data_in = 6'b100000;
end

InstructionFetcher m_InstructionFecher
(
.IR_Write(1),
.PC_Write(1),
.PC0_Write(1),
.PC_Data(PC_in_select == 0 ? PC_data_out + 1 : PC_data_in),
.clk_im(clk_cpu),
.reset(rst),
.PC_0(PC0_data_out),
.PC(PC_data_out),
.Instruction(Instruction) 
);

InstructionDecoderI m_Docoder
(
.Instruction(Instruction),
.funct7(funct7),
.funct3(funct3),
.opmask(opmask), //操作类型的掩码
.rs1(rs1), 
.rs2(rs2), 
.rd(rd), 
.imm32(imm32)
);

Display m_Display
(
.clk(clk),             
.rst(rst),             
.data(data_display == 3'b000 ? funct7:
      data_display == 3'b001 ? funct3:
      data_display == 3'b010 ? opmask:
      data_display == 3'b011 ? rs1:
      data_display == 3'b100 ? rs2:
      data_display == 3'b101 ? rd:
      data_display == 3'b110 ? imm32:
      data_display == 3'b111 ? Instruction :
      32'b0),     
.enable(enable),         
.which(which),
.seg(seg)   
);

endmodule

//-----------------------------------------------------------------------

module top // CPU Top
(
   input [31:0] sw,
   input [6:1] swb,
   input clk,
   output [2:0] which,
   output [7:0] seg,
   output enable
);

wire clk_cpu;
wire rst;
wire [3:0] display_select;
wire [31:0] instruction;

assign clk_cpu = swb[6];
assign rst = swb[5];
assign display_select = sw[31:28];

wire [2:0] w_data_s;
wire SE_s;
wire [1:0] Size_s;
wire Mem_Write;
wire [3:0] ALU_OP;
wire rs2_imm_s;
wire Reg_Write;   
wire IR_Write;   
wire PC0_Write;   
wire PC_Write;   
wire PC_s;    
wire [31:0] PC_Data;
wire [5:0] PC_0;
wire [31:0] Instruction;
wire [6:0] funct7;
wire [2:0] funct3;
wire [9:0] opmask;
wire [4:0] rs1_addr;
wire [4:0] rs2_addr;
wire [4:0] rd_addr;
wire [31:0] rs1_data;
wire [31:0] rs2_data;
wire [31:0] mem_data;
wire [31:0] imm32;
wire [3:0] FR;
wire [31:0] F;
wire [31:0] MDR_data;
wire [5:0] PC;
wire [4:0] status;

InstructionFetcher m_InstructionFetcher
(
   .IR_Write(IR_Write),           
   .PC_Write(PC_Write),           
   .PC0_Write(PC0_Write),          
   .PC_Data(PC_s == 0? PC + 1:
             PC_s == 1? PC_0 + imm32:
             PC_s == 2? F : 
             6'b0),      
   .clk_im(clk_cpu),             
   .reset(rst),              
   .PC_0(PC_0),    
   .PC(PC),    
   .Instruction(Instruction) 
);

InstructionDecoderI m_InstructionDecoder
(
.Instruction(Instruction),
.funct7(funct7),     
.funct3(funct3),     
.opmask(opmask), 
.rs1(rs1_addr),        
.rs2(rs2_addr),        
.rd(rd_addr),         
.imm32(imm32)      
);

CU m_CU
(
.opmask(opmask),
.funct7(funct7),
.funct3(funct3),
.FR(FR),
.reset(rst),
.clk(clk_cpu),
.w_data_s(w_data_s),
.SE_s(SE_s),
.Size_s(Size_s),
.Mem_Write(Mem_Write),
.ALU_OP(ALU_OP),
.rs2_imm_s(rs2_imm_s),
.Reg_Write(Reg_Write),
.IR_Write(IR_Write),
.PC0_Write(PC0_Write),
.PC_Write(PC_Write),
.PC_s(PC_s),
.current_state(status)
);

Regs m_Regs
(
.clk_Regs(!clk_cpu),         
.Reg_Write(Reg_Write),
.W_data(w_data_s == 0? F:
        w_data_s == 1? imm32: 
        w_data_s == 2? MDR_data:
        w_data_s == 3? {26'b0, PC}:
        w_data_s == 4? {26'b0, PC_0} + imm32: 
        32'b0), 
.R_Addr_A(rs1_addr),   
.R_Addr_B(rs2_addr),   
.W_Addr(rd_addr),     
.rst(rst),              
.R_Data_A(rs1_data), 
.R_Data_B(rs2_data)  
);

ALU m_ALU
(
.a_input(rs1_data),
.b_input(rs2_imm_s == 0? rs2_data:imm32),
.alu_op(ALU_OP), 
.clk_alu(!clk_cpu),
.F(F),
.FR(FR) 
);

DM m_DM
(
.M_W_Data(rs2_data),     
.DM_Addr(F),       
.clk_dm(clk_cpu),              
.SE_s(SE_s), //0:零扩展， 1：符号扩展
.Size_s(Size_s),//00:按字节
.Mem_Write(Mem_Write),           
.rst(rst),                 
.M_R_Data(mem_data) 
);

MDR m_MDR
(
.data_in(mem_data),
.clk(!clk_cpu),
.data_out(MDR_data)
);

Display m_Display
(
.clk(clk),             
.rst(rst),             
.data(display_select == 4'b0000 ? {27'b0, status}:
      display_select == 4'b0001 ? F:
      display_select == 4'b0010 ? Instruction:
      display_select == 4'b0011 ? imm32:
      display_select == 4'b0100 ? rs1_data:
      display_select == 4'b0101 ? rs2_data:
      display_select == 4'b0110 ? {31'b0, rs2_imm_s}:
      display_select == 4'b0111 ? {27'b0, rs1_addr}:
      display_select == 4'b1000 ? {27'b0, rs2_addr}:
      display_select == 4'b1001 ? {27'b0, rd_addr}:
      display_select == 4'b1010 ? {31'b0, Reg_Write}:
      {26'b0, PC}),     
.enable(enable),         
.which(which),
.seg(seg)   
);

endmodule

//------------------------------------------------------------------------

ex8 IM
IM[0]  <= 32'h87600093;		//addi x1 x0 -1930    #x1=0xFFFF_F876
IM[1]  <= 32'h00400113;		//addi x2 x0 4        #x2=0x0000_0004  
IM[2]  <= 32'h002081B3;		//add x3 x1 x2        #x3=0xFFFF_F87A
IM[3]  <= 32'h40208233;		//sub x4 x1 x2        #x4=0xFFFF_F872
IM[4]  <= 32'h002092B3;		//sll x5 x1 x2        #x5=0xFFFF_8760
IM[5]  <= 32'h0020D333;		//srl x6 x1 x2        #x6=0x0FFF_FF87
IM[6]  <= 32'h4020D3B3;		//sra x7 x1 x2        #x7=0xFFFF_FF87
IM[7]  <= 32'h0020A433;		//slt x8 x1 x2        #x8=0x0000_0001
IM[8]  <= 32'h0020B4B3;		//sltu x9 x1 x2       #x9=0x0000_0000
IM[9]  <= 32'h0062F533;		//and x10 x5 x6       #x10=0x0FFF_8700
IM[10] <= 32'h0062E5B3;		//or x11 x5 x6        #x11=0xFFFF_FFE7
IM[11] <= 32'h0062C633;		//xor x12 x5 x6       #x12=0xF000_78E7
IM[12] <= 32'h800006B7;		//lui x13 524288      #x13=0x8000_0000
IM[13] <= 32'hFFF68713;		//addi x14 x13 -1     #x14=0x7FFF_FFFF
IM[14] <= 32'h12370793;		//addi x15 x14 291    #x15=0x8000_0122
IM[15] <= 32'h00379813;		//slli x16 x15 3      #x16=0x0000_0910
IM[16] <= 32'h0037D893;		//srli x17 x15 3      #x17=0x1000_0024
IM[17] <= 32'h4037D913;		//srai x18 x15 3      #x18=0xF000_0024
IM[18] <= 32'hFFF92993;		//slti x19 x18 -1     #x19=0x0000_0001
IM[19] <= 32'hFFF93A13;		//sltiu x20 x18 -1    #x20=0x0000_0001
IM[20] <= 32'h00192A93;		//slti x21 x18 1      #x21=0x0000_0001
IM[21] <= 32'h00193B13;		//sltiu x22 x18 1     #x22=0x0000_0000
IM[22] <= 32'h0FF67B93;		//andi x23 x12 255    #x23=0x0000_00E7
IM[23] <= 32'h0FF66B93;		//ori x23 x12 255     #x23=0xF000_78FF
IM[24] <= 32'h00010C37;		//lui x24 16          #x24=0x0001_0000
IM[25] <= 32'hFFFC0C13;		//addi x24 x24 -1     #x24=0x0000_FFFF
IM[26] <= 32'hFFFC4C93;		//xori x25 x24 -1	    #x25=0xFFFF_0000

ex10 IM
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
IM[10]  = 32'h01C383B3;		//add x7 x7 x28       #累加
IM[11] = 32'h00428293;		//addi x5 x5 4        #移动数据区指针
IM[12] = 32'hFFF30313;		//addi x6 x6 -1       #计数器-1
IM[13] = 32'h00030163;		//beq x6 x0 2         #计数值=0，累加完成，退出循环
IM[14] = 32'hFFBFF06F;		//jal x0 -6           #计数值≠0，继续累加，跳转至循环体首部

IM[15] = 32'h00762023;		//sw x7 0(x12)        #累加和，存到指定单元                   exit
IM[16] = 32'h00008067;		//jalr x0 x1 0        #子程序返回