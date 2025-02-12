module full_adder_tb();
    logic a1;
    logic b1;
    logic c1;
    logic sum1;
    logic carry1;

    full_adder UUT(
        .a(a1),
        .b(b1),
        .c(c1),
        .sum(sum1),
        .carry(carry1)
    );
initial
    begin
        a1 = 0; b1 = 0; c1 = 0;
        #10;
        a1 = 0; b1 = 0; c1 = 1;
        #10;
        a1 = 0; b1 = 1; c1 = 0;
        #10;
        a1 = 0; b1 = 1; c1 = 1;
        #10;
        a1 = 1; b1 = 0; c1 = 0;
        #10;
        a1 = 1; b1 = 0; c1 = 1;
        #10;
        a1 = 1; b1 = 1; c1 = 0;
        #10;
        a1 = 1; b1 = 1; c1 = 1;
        #10;
        $stop;
    end
initial
    begin
        $monitor("a=%b, b=%b, c=%b, sum=%b, carry=%b",a1,b1,c1,sum1,carry1);
    end

endmodule