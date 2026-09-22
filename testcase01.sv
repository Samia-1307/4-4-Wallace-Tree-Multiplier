class testcase01;

  virtual alu_if vif;
  environment env;

  function new(virtual alu_if vif);
    this.vif = vif;
    this.env = new(vif);
  endfunction

  task run();
    $display("[TESTCASE01] Starting random functional testcase...");
    env.run_random_functional(1024);
    $display("[TESTCASE01] Random functional testcase completed.");
  endtask

endclass