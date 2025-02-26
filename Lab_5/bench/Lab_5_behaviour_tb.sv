module Lab5_behavioral_tb;

    logic [3:0] num_tb;
    logic [2:0] sel_tb;
    logic A, B, C, D, E, F, G, DP;
    logic [7:0] AN;

    localparam period = 10;

    Lab5_behavioral UUT (
        .num(num_tb),
        .sel(sel_tb),
        .A(A),
        .B(B),
        .C(C),
        .D(D),
        .E(E),
        .F(F),
        .G(G),
        .DP(DP),
        .AN(AN)
    );

    // Test sequence
    initial begin
        num_tb = 4'b0000; sel_tb = 3'b000; #period;
        num_tb = 4'b0001; sel_tb = 3'b001; #period;
        num_tb = 4'b0010; sel_tb = 3'b010; #period;
        num_tb = 4'b0011; sel_tb = 3'b011; #period;
        num_tb = 4'b0100; sel_tb = 3'b100; #period;
        num_tb = 4'b0101; sel_tb = 3'b101; #period;
        num_tb = 4'b0110; sel_tb = 3'b110; #period;
        num_tb = 4'b0111; sel_tb = 3'b111; #period;
        num_tb = 4'b1000; sel_tb = 3'b000; #period;
        num_tb = 4'b1001; sel_tb = 3'b001; #period;
        num_tb = 4'b1010; sel_tb = 3'b010; #period;
        num_tb = 4'b1011; sel_tb = 3'b011; #period;
        num_tb = 4'b1100; sel_tb = 3'b100; #period;
        num_tb = 4'b1101; sel_tb = 3'b101; #period;
        num_tb = 4'b1110; sel_tb = 3'b110; #period;
        num_tb = 4'b1111; sel_tb = 3'b111; #period;
        $stop;
    end 

    // Monitor the outputs of the DUT
    initial begin
        $monitor("num=%b, sel=%b, A=%b, B=%b, C=%b, D=%b, E=%b, F=%b, G=%b, DP=%b, AN=%b", 
                 num_tb, sel_tb, A, B, C, D, E, F, G, DP, AN);
    end

endmodule