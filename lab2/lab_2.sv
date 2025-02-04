


module lab_2(
         input a,
         input b,
         input c,
         output x,
         output y
         );
   assign y = (~(a&b)^(a|b))&(a|b);
   assign x= (~(c))^(a|b);

endmodule
