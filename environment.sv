class environment;

  virtual alu_if vif;

  mailbox #(transaction) gen2drv;
  mailbox #(transaction) drv2sb;
  mailbox #(transaction) mon2sb;

  generator  gen;
  driver     drv;
  monitor    mon;
  scoreboard sb;

  int direct_pass;
  int direct_fail;

  function new(virtual alu_if vif);
    this.vif = vif;

    gen2drv = new();
    drv2sb  = new();
    mon2sb  = new();

    gen = new(gen2drv);
    drv = new(vif, gen2drv, drv2sb);
    mon = new(vif, mon2sb);
    sb  = new(drv2sb, mon2sb);

    direct_pass = 0;
    direct_fail = 0;
  endfunction

  function automatic real calc_expected_coverage(int possible_cases, int total_txns);
    real ratio;
    real miss_prob;
    int  k;

    ratio     = (possible_cases - 1.0) / possible_cases;
    miss_prob = 1.0;

    for (k = 0; k < total_txns; k = k + 1) begin
      miss_prob = miss_prob * ratio;
    end

    calc_expected_coverage = (1.0 - miss_prob) * 100.0;
  endfunction

  task automatic check_value(string tag, logic [31:0] got, logic [31:0] exp);
    if (got === exp) begin
      direct_pass++;
      $display("[CHK] %s --> PASSED (got=%0d expected=%0d)", tag, got, exp);
    end
    else begin
      direct_fail++;
      $display("[CHK] %s --> FAILED (got=%0d expected=%0d)", tag, got, exp);
    end
  endtask

  // --------------------------------------------------
  // TESTCASE 01 : random functional + functional coverage
  // --------------------------------------------------
  task run_random_functional(int total_txns = 512);
    real actual_cov;
    real expected_cov;
    int  possible_cases;

    possible_cases = 256;

    fork
      mon.run();
    join_none

    drv.reset_dut("INITIAL RESET");

    gen.gen_random(total_txns);
    drv.drive_n(total_txns);
    drv.apply_dummy(2);

    sb.compare_n(total_txns);
    sb.report("RANDOM FUNCTIONAL TEST SUMMARY");

    actual_cov   = mon.get_cross_coverage();
    expected_cov = calc_expected_coverage(possible_cases, total_txns);

    $display("[ENV] Random tests run            = %0d", total_txns);
    $display("[ENV] Possible combinations       = %0d", possible_cases);
    $display("[ENV] Actual functional coverage  = %0.2f%%", actual_cov);
    $display("[ENV] Expected random coverage    = %0.2f%%", expected_cov);
    $display("[ENV] Reset checks passed         = %0d", drv.reset_pass);
    $display("[ENV] Reset checks failed         = %0d", drv.reset_fail);

    if ((sb.fail_count == 0) && (drv.reset_fail == 0))
      $display("[ENV] OVERALL RESULT --> ALL TESTS PASSED");
    else
      $display("[ENV] OVERALL RESULT --> SOME TESTS FAILED");

    disable fork;
  endtask

  // --------------------------------------------------
  // TESTCASE 02 : reset functionality test
  // --------------------------------------------------
  task run_reset_test();
    transaction tr;
    transaction post_q[$];

    drv.reset_dut("INITIAL RESET");

    // Drive two vectors that should be aborted by midstream reset
    tr = new(); tr.a = 4'd9;  tr.b = 4'd9;   tr.id = 0; drv.drive_one(tr, 1'b0);
    tr = new(); tr.a = 4'd11; tr.b = 4'd13;  tr.id = 1; drv.drive_one(tr, 1'b0);

    // Assert reset before these results can reach output
    #3;
    drv.midstream_reset("MIDSTREAM RESET");

    // Start monitor only after reset so stale pre-reset data does not enter scoreboard
    fork
      mon.run();
    join_none

    // Post-reset directed vectors
    tr = new(); tr.a = 4'd1;  tr.b = 4'd1;   tr.id = 0; post_q.push_back(tr);
    tr = new(); tr.a = 4'd2;  tr.b = 4'd8;   tr.id = 1; post_q.push_back(tr);
    tr = new(); tr.a = 4'd5;  tr.b = 4'd3;   tr.id = 2; post_q.push_back(tr);
    tr = new(); tr.a = 4'd15; tr.b = 4'd15;  tr.id = 3; post_q.push_back(tr);

    foreach (post_q[idx]) begin
      drv.drive_one(post_q[idx], 1'b1);
    end

    drv.apply_dummy(2);

    sb.compare_n(post_q.size());
    sb.report("RESET TEST SUMMARY");

    $display("[ENV] Reset checks passed = %0d", drv.reset_pass);
    $display("[ENV] Reset checks failed = %0d", drv.reset_fail);

    if ((sb.fail_count == 0) && (drv.reset_fail == 0))
      $display("[ENV] OVERALL RESULT --> RESET TEST PASSED");
    else
      $display("[ENV] OVERALL RESULT --> RESET TEST FAILED");

    disable fork;
  endtask

  // --------------------------------------------------
  // TESTCASE 03 : pipeline / register functionality test
  // --------------------------------------------------
  task run_pipeline_test();
    transaction tr;
    transaction seq_q[$];

    // -----------------------------
    // Part A: direct latency/register check
    // -----------------------------
    drv.reset_dut("PIPELINE INIT RESET");

    tr = new();
    tr.a  = 4'd3;
    tr.b  = 4'd5;
    tr.id = 0;

    drv.drive_one(tr, 1'b0);

    // After 1st rising edge: a_r/b_r must capture input, p still 0
    @(posedge vif.clk); #1;
    check_value("Stage-0 register capture a_r", vif.a_r_obs, 4'd3);
    check_value("Stage-0 register capture b_r", vif.b_r_obs, 4'd5);
    check_value("Output after first edge",      vif.p,       8'd0);

    // After 2nd rising edge: output still not valid
    @(posedge vif.clk); #1;
    check_value("Output after second edge",     vif.p,       8'd0);

    // After 3rd rising edge: final output must appear
    @(posedge vif.clk); #1;
    check_value("Output after third edge",      vif.p,       8'd15);

    // -----------------------------
    // Part B: back-to-back pipeline ordering check
    // -----------------------------
    drv.reset_dut("PIPELINE RESTART RESET");

    fork
      mon.run();
    join_none

    tr = new(); tr.a = 4'd1;  tr.b = 4'd1;   tr.id = 0; seq_q.push_back(tr);
    tr = new(); tr.a = 4'd2;  tr.b = 4'd3;   tr.id = 1; seq_q.push_back(tr);
    tr = new(); tr.a = 4'd4;  tr.b = 4'd5;   tr.id = 2; seq_q.push_back(tr);
    tr = new(); tr.a = 4'd15; tr.b = 4'd15;  tr.id = 3; seq_q.push_back(tr);

    foreach (seq_q[idx]) begin
      drv.drive_one(seq_q[idx], 1'b1);
    end

    drv.apply_dummy(2);

    sb.compare_n(seq_q.size());
    sb.report("PIPELINE ORDERING TEST SUMMARY");

    $display("[ENV] Direct check pass count = %0d", direct_pass);
    $display("[ENV] Direct check fail count = %0d", direct_fail);
    $display("[ENV] Reset checks passed     = %0d", drv.reset_pass);
    $display("[ENV] Reset checks failed     = %0d", drv.reset_fail);

    if ((sb.fail_count == 0) && (drv.reset_fail == 0) && (direct_fail == 0))
      $display("[ENV] OVERALL RESULT --> PIPELINE / REGISTER TEST PASSED");
    else
      $display("[ENV] OVERALL RESULT --> PIPELINE / REGISTER TEST FAILED");

    disable fork;
  endtask

endclass