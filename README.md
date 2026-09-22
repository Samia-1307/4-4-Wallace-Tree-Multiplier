# 4-4-Wallace-Tree-Multiplier
A complete RTL-to-GDSII implementation of a pipelined 4x4 Wallace Tree Multiplier using Verilog and Cadence tools, featuring comprehensive SystemVerilog verification.
# Design and Physical Implementation of a 4x4 Wallace Tree Multiplier

## Overview
This repository contains the RTL design, verification environment, and physical implementation of a 4x4 Wallace tree multiplier. The multiplier takes two 4-bit input operands and produces an 8-bit output through parallel partial product generation and reduction. To improve throughput, a pipelined architecture with a 2-cycle latency is implemented. 

This project was developed for the EEE 468 (July 2025) VLSI Laboratory at the Bangladesh University of Engineering and Technology (BUET) by Section G2, Group 03.

## Architecture
The multiplication process is divided into two major functional segments in a pipelined structure:
* **Partial Product Generation & Reduction:** Generates 16 partial products which are compressed in parallel using a Wallace tree structure composed of half adders and full adders.
* **Final Addition:** The final summation of the reduced outputs (sum and carry rows) is performed using a carry-propagate adder to produce the 8-bit result.
* **Pipelining:** Pipeline registers are inserted between the compression and final summation stages, allowing the design to process data with a 2-cycle latency and high throughput.

## Verification
The functional correctness of the design is verified using SystemVerilog testbenches.
* **Directed Testbench:** Verifies reset conditions and applies random as well as exhaustive input combinations (all 256 possible combinations).
* **Layered Testbench:** Utilizes an object-oriented verification environment (Generator, Driver, Monitor, Scoreboard) to verify functional behavior, reset operation, register capture, pipeline latency, and input ordering. The random functional testing achieved 98.83% actual functional coverage.

## Synthesis and Physical Design
The design was synthesized and physically implemented using Cadence tools.
* **Synthesis:** Performed using Cadence Genus. A parameter sweep determined that a 10 ns clock period provided the best trade-off between lower power consumption and acceptable performance.
* **Physical Implementation:** Executed using Cadence Innovus, which included floorplanning with a 0.60 core utilization, placement, clock tree synthesis, and routing.
* **Power Grid:** Created using Metal4 vertical stripes for VDD and VSS with a 0.4 µm width and 0.6 µm spacing.
* **Sign-off:** The final layout underwent metal fill insertion and passed the Design Rule Check (DRC) with 0 violations.


## Team Members
* **Golam An Noor Siddique**- Physical Design
* **Md Al Saif Hossain Anay**- RTL code, Synthesis
* **Md Nakib**- Layered Test Bench
* **Md Mostafizur Rahman**- RTL code, Directed Test Bench
* **Samia Hossain**- Physical Design
