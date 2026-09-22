class monitor;

  virtual alu_if vif;
  mailbox #(transaction) mon2sb;

  bit vld_d0;
  bit vld_d1;
  int observed_count;

  bit [3:0] cov_a;
  bit [3:0] cov_b;

  covergroup cg_inputs;
    option.per_instance = 1;

    cp_a : coverpoint cov_a {
      bins a_vals[] = {[0:15]};
    }

    cp_b : coverpoint cov_b {
      bins b_vals[] = {[0:15]};
    }

    axb : cross cp_a, cp_b;
  endgroup

  function new(
    virtual alu_if         vif,
    mailbox #(transaction) mon2sb
  );
    this.vif            = vif;
    this.mon2sb         = mon2sb;
    this.vld_d0         = 1'b0;
    this.vld_d1         = 1'b0;
    this.observed_count = 0;
    this.cg_inputs      = new();
  endfunction

  task run();
    transaction tr;

    forever begin
      @(posedge vif.clk);

      if (vif.rst) begin
        vld_d0 = 1'b0;
        vld_d1 = 1'b0;
      end
      else begin
        if (vif.tb_valid) begin
          cov_a = vif.a;
          cov_b = vif.b;
          cg_inputs.sample();
        end

        #1;

        if (vld_d1) begin
          tr     = new();
          tr.p   = vif.p;
          tr.id  = observed_count;
          mon2sb.put(tr);
          observed_count++;
        end

        vld_d1 = vld_d0;
        vld_d0 = vif.tb_valid;
      end
    end
  endtask

  function real get_cross_coverage();
    return cg_inputs.axb.get_inst_coverage();
  endfunction

endclass