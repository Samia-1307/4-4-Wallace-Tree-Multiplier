class driver;

  virtual alu_if vif;

  mailbox #(transaction) gen2drv;
  mailbox #(transaction) drv2sb;

  int reset_pass;
  int reset_fail;

  function new(
    virtual alu_if         vif,
    mailbox #(transaction) gen2drv,
    mailbox #(transaction) drv2sb
  );
    this.vif        = vif;
    this.gen2drv    = gen2drv;
    this.drv2sb     = drv2sb;
    this.reset_pass = 0;
    this.reset_fail = 0;
  endfunction

  task automatic reset_dut(string tag = "RESET");
    vif.rst      = 1'b1;
    vif.a        = 4'd0;
    vif.b        = 4'd0;
    vif.tb_valid = 1'b0;

    #1;
    if (vif.p === 8'd0) begin
      reset_pass++;
      $display("[DRV] %s PASSED: p = %0d", tag, vif.p);
    end
    else begin
      reset_fail++;
      $display("[DRV] %s FAILED: p = %0d, expected = 0", tag, vif.p);
    end

    repeat (2) @(negedge vif.clk);
    vif.rst = 1'b0;
    $display("[DRV] %s deasserted.", tag);
  endtask

  task automatic midstream_reset(string tag = "MIDSTREAM RESET");
    vif.rst      = 1'b1;
    vif.a        = 4'd0;
    vif.b        = 4'd0;
    vif.tb_valid = 1'b0;

    #1;
    if (vif.p === 8'd0) begin
      reset_pass++;
      $display("[DRV] %s PASSED: p = %0d", tag, vif.p);
    end
    else begin
      reset_fail++;
      $display("[DRV] %s FAILED: p = %0d, expected = 0", tag, vif.p);
    end

    @(negedge vif.clk);
    vif.rst = 1'b0;
    $display("[DRV] %s deasserted.", tag);
  endtask

  task automatic drive_one(transaction tr, bit send_to_scoreboard = 1'b1);
    @(negedge vif.clk);
    vif.a        = tr.a;
    vif.b        = tr.b;
    vif.tb_valid = 1'b1;

    if (send_to_scoreboard)
      drv2sb.put(tr.copy());
  endtask

  task automatic drive_n(int total_txns);
    transaction tr;

    repeat (total_txns) begin
      gen2drv.get(tr);
      drive_one(tr, 1'b1);
    end
  endtask

  task automatic apply_dummy(int n = 1);
    repeat (n) begin
      @(negedge vif.clk);
      vif.a        = 4'd0;
      vif.b        = 4'd0;
      vif.tb_valid = 1'b0;
    end
  endtask

endclass