class scoreboard;

  mailbox #(transaction) drv2sb;
  mailbox #(transaction) mon2sb;

  int case_no;
  int pass_count;
  int fail_count;

  function new(
    mailbox #(transaction) drv2sb,
    mailbox #(transaction) mon2sb
  );
    this.drv2sb    = drv2sb;
    this.mon2sb    = mon2sb;
    this.case_no   = 0;
    this.pass_count = 0;
    this.fail_count = 0;
  endfunction

  task automatic compare_n(int total_txns);
    transaction exp_tr;
    transaction act_tr;
    bit [7:0] expected;

    repeat (total_txns) begin
      drv2sb.get(exp_tr);
      mon2sb.get(act_tr);

      expected = exp_tr.expected_product();
      case_no++;

      if (act_tr.p === expected) begin
        pass_count++;
        $display("CASE %0d : a = %0d, b = %0d, y = %0d, expected = %0d --> PASSED",
                 case_no, exp_tr.a, exp_tr.b, act_tr.p, expected);
      end
      else begin
        fail_count++;
        $display("CASE %0d : a = %0d, b = %0d, y = %0d, expected = %0d --> FAILED",
                 case_no, exp_tr.a, exp_tr.b, act_tr.p, expected);
      end
    end
  endtask

  function void report(string title = "SCOREBOARD SUMMARY");
    $display(" ");
    $display("==================================================");
    $display("%s", title);
    $display("==================================================");
    $display("Functional cases PASSED = %0d", pass_count);
    $display("Functional cases FAILED = %0d", fail_count);
    $display("Total functional cases  = %0d", pass_count + fail_count);
    $display("==================================================");
  endfunction

endclass