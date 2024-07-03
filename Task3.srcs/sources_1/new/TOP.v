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
        w_data_s == 2? mem_data:
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