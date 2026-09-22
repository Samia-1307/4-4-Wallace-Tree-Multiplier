class testcase02;

  virtual alu_if vif;
  environment env;

  function new(virtual alu_if vif);
    this.vif = vif;
    this.env = new(vif);
  endfunction

  task run();
    $display("[TESTCASE02] Starting reset testcase...");
    env.run_reset_test();
    $display("[TESTCASE02] Reset testcase completed.");
  endtask

endclass