class generator;

  mailbox #(transaction) gen2drv;

  function new(mailbox #(transaction) gen2drv);
    this.gen2drv = gen2drv;
  endfunction

  task gen_random(int total_txns);
    transaction tr;

    for (int idx = 0; idx < total_txns; idx++) begin
      tr = new();

      if (!tr.randomize()) begin
        $display("[GEN] ERROR: Randomization failed at idx=%0d", idx);
        $finish;
      end

      tr.id = idx;
      gen2drv.put(tr);
    end

    $display("[GEN] Generated %0d random transactions.", total_txns);
  endtask

endclass