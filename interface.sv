`timescale 1ns/1ps

interface alu_if;

  logic        clk;
  logic        rst;
  logic [3:0]  a;
  logic [3:0]  b;
  logic [7:0]  p;

  // TB-only valid
  logic        tb_valid;

  // Internal DUT observation signals
  logic [3:0]  a_r_obs;
  logic [3:0]  b_r_obs;
  logic [8:0]  sum_r_obs;
  logic [8:0]  carry_r_obs;

endinterface