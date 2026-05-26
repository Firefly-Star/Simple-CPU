# Simple-CPU

A RISC-V RV32I CPU implementation on FPGA using Verilog HDL.

## Description

This project implements a 17-instruction subset of the RISC-V RV32I architecture on FPGA. Built with Xilinx Vivado, it includes a 5-stage pipeline CPU design.

## Tech Stack

- Verilog HDL
- Xilinx Vivado IDE
- FPGA prototyping board

## Features

- RISC-V RV32I instruction subset (17 instructions)
- 5-stage pipeline architecture
- FPGA synthesis and implementation

## Structure

```
Task3.srcs/     — Source files (Verilog modules)
Task3.xpr       — Vivado project file
Top.v           — Top-level module
CU指令.v        — Control unit
Ex*.bit         — Bitstream files
```
