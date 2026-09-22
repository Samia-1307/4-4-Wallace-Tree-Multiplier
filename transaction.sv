class transaction;

  rand bit [3:0] a;
  rand bit [3:0] b;
       bit [7:0] p;
       int       id;

  function new();
    a  = 4'd0;
    b  = 4'd0;
    p  = 8'd0;
    id = -1;
  endfunction

  function automatic transaction copy();
    transaction tr;
    tr    = new();
    tr.a  = this.a;
    tr.b  = this.b;
    tr.p  = this.p;
    tr.id = this.id;
    return tr;
  endfunction

  function automatic bit [7:0] expected_product();
    expected_product = {4'b0, a} * {4'b0, b};
  endfunction

endclass