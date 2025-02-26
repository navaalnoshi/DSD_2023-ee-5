module Lab5_structural(
    output logic A, B, C, D, E, F, G, DP,
    output logic [7:0] AN,
    input logic [2:0] sel,
    input logic [3:0] num
);

    // For Cathodes
    assign A = (~num[3] & ~num[2] & ~num[1] & num[0]) | (num[3] & ~num[2] & num[1] & num[0]) | (~num[3] & num[2] & ~num[1] & ~num[0]) | (num[3] & num[2] & ~num[1] & num[0]);
    assign B = (~num[3] & num[2] & ~num[1] & num[0]) | (num[3] & num[2] & ~num[0]) | (num[3] & num[1] & num[0]) | (num[2] & num[1] & ~num[0]);
    assign C = (~num[3] & ~num[2] & num[1] & ~num[0]) | (num[3] & num[2] & ~num[0]) | (num[3] & num[2] & num[1]);
    assign D = (~num[3] & ~num[2] & ~num[1] & num[0]) | (~num[3] & num[2] & ~num[1] & ~num[0]) | (num[3] & ~num[2] & num[1] & ~num[0]) | (num[2] & num[1] & num[0]);
    assign E = (~num[3] & num[0]) |(~num[2] & ~num[1] & num[0]) |  (~num[3] & num[2] & ~num[1]) ;
    assign F = (~num[3] & ~num[2] & num[0]) | (~num[3] & ~num[2] & num[1]) |   (~num[3] & num[1] & num[0]) | (num[3] & num[2] & ~num[1] & num[0]);
    assign G = (num[3] & num[2] & ~num[1] & ~num[0]) | (~num[3] & num[2] & num[1] & num[0]) |  (~num[3] & ~num[2] & ~num[1]);
    assign DP = 0; 
    
    // For Anodes
    assign AN[0] = sel[2] | sel[1] | (~sel[2] & (sel[0]));
    assign AN[1] = sel[2] | sel[1] | (~sel[2] & (~sel[0]));
    assign AN[2] = sel[2] | ~sel[1] | (~sel[2] & (sel[0]));
    assign AN[3] = sel[2] | ~sel[1] | (~sel[2] & (~sel[0]));
    assign AN[4] = ~sel[2] | sel[1] | (sel[2] & (sel[0]));
    assign AN[5] = ~sel[2] | sel[1] | (sel[2] & (~sel[0]));
    assign AN[6] = ~sel[2] | ~sel[1] | (sel[2] & (sel[0]));
    assign AN[7] = ~sel[2] | ~sel[1] | (sel[1] & (~sel[0]));
endmodule
