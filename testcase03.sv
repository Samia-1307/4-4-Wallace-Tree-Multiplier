class testcase03;

  virtual alu_if vif;
  environment env;

  function new(virtual alu_if vif);
    this.vif = vif;
    this.env = new(vif);
  endfunction

  task run();
    $display("[TESTCASE03] Starting pipeline / register testcase...");
    env.run_pipeline_test();
    $display("[TESTCASE03] Pipeline / register testcase completed.");
  endtask

endclass