module full_adder(
    input logic a,
    input logic b,
    input logic c,
    output logic sum,
    output logic carry
);

    assign sum = (a ^ b) ^ c;
    assign carry = (a & b) | (c & (a ^ b));
endmodule
