module lab2_tb();
  logic ae;
  logic be;
  logic ce;
  logic xe;
  logic ye;

localparam period = 10;

  lab_2 UUT (
    .a(ae),
    .b(be),
    .c(ce),
    .x(xe),
    .y(ye)
  );
    initial
        begin
            ae = 0; be = 0; ce = 0;
            #10;
            ae = 0; be = 0; ce = 1;
            #10;
            ae = 0; be = 1; ce = 0;
            #10;
            ae = 0; be = 1; ce = 1;
            #10;
            ae = 1; be = 0; ce = 0;
            #10;
            ae = 1; be = 0; ce = 1;
            #10;
            ae = 1; be = 1; ce = 0;
            #10;
            ae = 1; be = 1; ce = 1;
            #10;
            $finish;
        end
    initial
        begin
           $monitor("a=%b, b=%b, c=%b, x=%b, y=%b", ae,be,ce,xe,ye);
        end
endmodule