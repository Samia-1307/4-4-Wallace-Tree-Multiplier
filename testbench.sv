`timescale 1ns/1ps

module testbench;

  alu_if vif();

  `ifdef TESTCASE02
    testcase02 tc;
  `elsif TESTCASE03
    testcase03 tc;
  `else
    testcase01 tc;
  `endif

  // DUT
  alu dut (
    .clk (vif.clk),
    .rst (vif.rst),
    .a   (vif.a),
    .b   (vif.b),
    .p   (vif.p)
  );

  // Internal observation mapping
  assign vif.a_r_obs     = dut.a_r;
  assign vif.b_r_obs     = dut.b_r;
  assign vif.sum_r_obs   = dut.sum_r;
  assign vif.carry_r_obs = dut.carry_r;

  // Clock
  initial begin
    vif.clk = 1'b0;
    forever #5 vif.clk = ~vif.clk;
  end

  // Cadence SHM dump
  initial begin
    $shm_open("waves_layered.shm");
    $shm_probe(testbench, "AS");
  end

  initial begin
    vif.rst      = 1'b0;
    vif.a        = 4'd0;
    vif.b        = 4'd0;
    vif.tb_valid = 1'b0;

    tc = new(vif);
    tc.run();

    #10;
    $finish;
  end

endmodule