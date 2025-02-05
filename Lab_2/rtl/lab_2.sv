


module lab_2(
         input a,
         input b,
         input c,
         output x,
         output y
         );
   assign x= (~(c))^(a|b); //first NOT of c then a OR b then together for both take XOR
   assign y = (a|b)&(~(a&b)^(a|b)); //  first the not of a AND b , with this then
   // take XOR with a OR b and finally with the result of this take AND with a OR b
  

endmodule
