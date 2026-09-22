`timescale 1ns/1ps



// ---------------------------

// Basic building blocks

// ---------------------------

module half_adder(

  input  wire a,

  input  wire b,

  output wire sum,

  output wire carry

);

  assign sum   = a ^ b;

  assign carry = a & b;

endmodule



module full_adder(

  input  wire a,

  input  wire b,

  input  wire cin,

  output wire sum,

  output wire carry

);

  assign sum   = a ^ b ^ cin;

  assign carry = (a & b) | (a & cin) | (b & cin);

endmodule



// ---------------------------

// 4x4 Wallace Tree Multiplier (Pipelined)

// Latency: 2 cycles (input sampled -> output valid after 2 rising edges)

// Throughput: 1 result per cycle (after pipeline fills)

// ---------------------------

module wallace(

  input  wire       clk,

  input  wire       rst,   // async active-high reset

  input  wire [3:0] a,

  input  wire [3:0] b,

  output reg  [7:0] p

);



  // =========================

  // Stage 0: input registers

  // =========================

  reg [3:0] a_r, b_r;

  always @(posedge clk or posedge rst) begin

    if (rst) begin

      a_r <= 4'b0;

      b_r <= 4'b0;

    end else begin

      a_r <= a;

      b_r <= b;

    end

  end



  // =========================

  // Stage 1: Wallace reduction (combinational) -> register 2 rows

  // =========================

  // Partial products (ppij = ai & bj), weight = i+j

  wire pp00 = a_r[0] & b_r[0];

  wire pp01 = a_r[0] & b_r[1];

  wire pp02 = a_r[0] & b_r[2];

  wire pp03 = a_r[0] & b_r[3];



  wire pp10 = a_r[1] & b_r[0];

  wire pp11 = a_r[1] & b_r[1];

  wire pp12 = a_r[1] & b_r[2];

  wire pp13 = a_r[1] & b_r[3];



  wire pp20 = a_r[2] & b_r[0];

  wire pp21 = a_r[2] & b_r[1];

  wire pp22 = a_r[2] & b_r[2];

  wire pp23 = a_r[2] & b_r[3];



  wire pp30 = a_r[3] & b_r[0];

  wire pp31 = a_r[3] & b_r[1];

  wire pp32 = a_r[3] & b_r[2];

  wire pp33 = a_r[3] & b_r[3];



  // Wallace-tree signals (chosen to end with two 9-bit rows)

  wire s4,  c4;   // w1

  wire s1,  c1;   // w2 (first compress)

  wire s6,  c6;   // w2 (second compress with carry from w1)

  wire s2,  c2;   // w3 (compress pp03,pp12,pp21)

  wire s5,  c5;   // w3 (compress pp30,s2,c1), leftover c6 remains as 2nd row bit

  wire s3,  c3;   // w4 (compress pp13,pp22,pp31)

  wire s9,  c9;   // w4 (compress s3,c2,c5)

  wire s7,  c7;   // w5 (compress pp23,pp32,c3)

  wire s10, c10;  // w5 (compress s7,c9)

  wire s8,  c8;   // w6 (compress pp33,c7)

  wire s11, c11;  // w6 (compress s8,c10)

  wire s12, c12;  // w7 (compress c8,c11) -> c12 becomes bit at weight 8



  // Column-by-column compression (Wallace style)

  half_adder HA_w1   (.a(pp01), .b(pp10), .sum(s4),  .carry(c4));

  full_adder FA_w2   (.a(pp02), .b(pp11), .cin(pp20), .sum(s1),  .carry(c1));

  half_adder HA_w2   (.a(s1),   .b(c4),   .sum(s6),  .carry(c6));



  full_adder FA_w3a  (.a(pp03), .b(pp12), .cin(pp21), .sum(s2),  .carry(c2));

  full_adder FA_w3b  (.a(pp30), .b(s2),   .cin(c1),   .sum(s5),  .carry(c5));



  full_adder FA_w4a  (.a(pp13), .b(pp22), .cin(pp31), .sum(s3),  .carry(c3));

  full_adder FA_w4b  (.a(s3),   .b(c2),   .cin(c5),   .sum(s9),  .carry(c9));



  full_adder FA_w5a  (.a(pp23), .b(pp32), .cin(c3),   .sum(s7),  .carry(c7));

  half_adder HA_w5   (.a(s7),   .b(c9),   .sum(s10), .carry(c10));



  half_adder HA_w6a  (.a(pp33), .b(c7),   .sum(s8),  .carry(c8));

  half_adder HA_w6b  (.a(s8),   .b(c10),  .sum(s11), .carry(c11));



  half_adder HA_w7   (.a(c8),   .b(c11),  .sum(s12), .carry(c12));



  // Two rows to be added in the final CPA:

  // sum_row has one bit per weight, carry_row holds the "leftover" bits.

  wire [8:0] sum_row_s1;

  wire [8:0] carry_row_s1;



  assign sum_row_s1[0] = pp00;  // w0

  assign sum_row_s1[1] = s4;    // w1

  assign sum_row_s1[2] = s6;    // w2

  assign sum_row_s1[3] = s5;    // w3

  assign sum_row_s1[4] = s9;    // w4

  assign sum_row_s1[5] = s10;   // w5

  assign sum_row_s1[6] = s11;   // w6

  assign sum_row_s1[7] = s12;   // w7

  assign sum_row_s1[8] = 1'b0;  // w8



  // leftover bit in weight 3 (from HA_w2 carry):

  // keep it as the second row bit at the same weight.

  wire [8:0] carry_row_tmp = (9'b1 << 3) & {9{c6}};

  // c12 is at weight 8 (from HA_w7 carry)

  wire [8:0] carry_row_tmp2 = (9'b1 << 8) & {9{c12}};



  assign carry_row_s1 = carry_row_tmp | carry_row_tmp2;



  // Register stage-1 rows

  reg [8:0] sum_r, carry_r;

  always @(posedge clk or posedge rst) begin

    if (rst) begin

      sum_r   <= 9'b0;

      carry_r <= 9'b0;

    end else begin

      sum_r   <= sum_row_s1;

      carry_r <= carry_row_s1;

    end

  end



  // =========================

  // Stage 2: final carry-propagate adder -> output register

  // =========================

  wire [9:0] add_res = sum_r + carry_r; // up to 10 bits



  always @(posedge clk or posedge rst) begin

    if (rst) begin

      p <= 8'b0;

    end else begin

      p <= add_res[7:0]; // 4x4 product fits in 8 bits

    end

  end



endmodule
