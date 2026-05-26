# Simple-CPU

基于 Verilog HDL 的 RISC-V RV32I FPGA CPU 实现。

## 描述

该项目在 FPGA 上实现了 RISC-V RV32I 架构的 17 条指令子集，使用 Xilinx Vivado 开发，包含 5 级流水线 CPU 设计。

## 技术栈

- Verilog HDL
- Xilinx Vivado IDE
- FPGA 开发板

## 功能

- RISC-V RV32I 指令子集（17 条指令）
- 5 级流水线架构
- FPGA 综合与实现

## 结构

```
Task3.srcs/     — 源文件（Verilog 模块）
Task3.xpr       — Vivado 项目文件
Top.v           — 顶层模块
CU指令.v        — 控制单元
Ex*.bit         — 比特流文件
```
