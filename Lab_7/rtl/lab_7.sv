`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/25/2025 09:34:25 PM
// Design Name: 
// Module Name: lab_7
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
module lab_7(
    input logic clk,         // system clock (100 MHz)
    input logic write,       // write signal
    input logic reset,       // reset signal
    input logic [3:0] num,   // 4-bit number input
    input logic [2:0] sel,   // selector input
    output reg [7:0] anode,  // anode signals for 7-segment displays
    output reg [6:0] seg,     // segment signals for 7-segment display
    output logic dp
);
    // Internal signals
    logic slow_clk;           // 100 Hz clock
    logic [3:0] q[7:0];       // Registers for display values
    logic  en [0:7];           // Enable signals for storage
    logic [3:0] m_out;        // Multiplexer output
    logic [16:0] clk_div;     // Clock divider
    logic [2:0] disp_counter; // Display counter
    logic [2:0] new_sel;

    // Condition for And gate
    always_comb begin 
        for (int i = 0; i < 8; i = i + 1) begin 
            en[i] = write & ~anode[i];
        end
    end

    // D flip-flops for storing values
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            q[0] <= 4'b0000; q[1] <= 4'b0000; q[2] <= 4'b0000; q[3] <= 4'b0000;
            q[4] <= 4'b0000; q[5] <= 4'b0000; q[6] <= 4'b0000; q[7] <= 4'b0000;
        end else begin
            if (en[0]) q[0] <= num;
            if (en[1]) q[1] <= num;
            if (en[2]) q[2] <= num;
            if (en[3]) q[3] <= num;
            if (en[4]) q[4] <= num;
            if (en[5]) q[5] <= num;
            if (en[6]) q[6] <= num;
            if (en[7]) q[7] <= num;
        end
    end

    // Clock frequency controller: decreases the frequency to 763Hz
    always_ff @(posedge clk or posedge reset) begin
        if (reset)
            clk_div <= 0;
        else
            clk_div <= clk_div + 1'b1;
    end
    
    assign slow_clk = clk_div[16];
    
    // Further decreases the frequency to 100Hz for each segment
    always_ff @(posedge slow_clk or posedge reset) begin
        if (reset)
            disp_counter <= 0;
        else
            disp_counter <= disp_counter + 1'b1;
    end
    
    // Select active display
    always_comb begin
        if (write)
            new_sel = sel;
        else
            new_sel = disp_counter;
    end

    // Multiplexer for selecting the active display value
    always_comb begin
        case (new_sel)
            3'b000: m_out = q[0];
            3'b001: m_out = q[1];
            3'b010: m_out = q[2];
            3'b011: m_out = q[3];
            3'b100: m_out = q[4];
            3'b101: m_out = q[5];
            3'b110: m_out = q[6];
            3'b111: m_out = q[7];
        endcase
    end

    // Seven-segment display decoder
    always_comb begin
        case (m_out)
            4'b0000 : seg = 7'b0000001;
            4'b0001 : seg = 7'b1001111;
            4'b0010 : seg = 7'b0010010;
            4'b0011 : seg = 7'b0000110;
            4'b0100 : seg = 7'b1001100;
            4'b0101 : seg = 7'b0100100;
            4'b0110 : seg = 7'b0100000;
            4'b0111 : seg = 7'b0001111;
            4'b1000 : seg = 7'b0000000;
            4'b1001 : seg = 7'b0000100;
            4'b1010 : seg = 7'b0001000;
            4'b1011 : seg = 7'b1100000;
            4'b1100 : seg = 7'b0110001;
            4'b1101 : seg = 7'b1000010;
            4'b1110 : seg = 7'b0110000;
            4'b1111 : seg = 7'b0111000;
            endcase
    end

    // Anode control for cycling through displays
    always_comb begin
        case (new_sel)
             3'b000 : anode = 8'b11111110;
             3'b001 : anode = 8'b11111101;
             3'b010 : anode = 8'b11111011;
             3'b011 : anode = 8'b11110111;
             3'b100 : anode = 8'b11101111;
             3'b101 : anode = 8'b11011111;
             3'b110 : anode = 8'b10111111;
             3'b111 : anode = 8'b01111111;
        endcase
    end
    assign dp=1;
endmodule


