module lab_2(
  input logic a,   
  input logic b,
  input logic c,
  output logic x,  
  output logic y
);

  logic or_out, xor_out; 

  assign or_out = a | b;
  assign x = (~c) ^ or_out;
  assign xor_out = (~(a & b)) ^ or_out;
  assign y = or_out & xor_out;

endmodule


