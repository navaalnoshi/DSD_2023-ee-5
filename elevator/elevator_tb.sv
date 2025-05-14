`timescale 1ns / 1ps

module elevator_tb();

    // Inputs
    logic        direction;
    logic [2:0]  req_floor;
    logic        clk;
    logic        reset;
    logic        emergency;
    logic        valid_in;

    // Outputs
    logic [6:0]  cathode;
    logic [7:0]  anode;
    logic        r;
    logic        g;
    logic        b;

    // Instantiate the Unit Under Test (UUT)
    elevator #(
        .COUNT_20S(20),
        .COUNT_1S(10)
    ) UUT (
        .direction(direction),
        .req_floor(req_floor),
        .clk(clk),
        .reset(reset),
        .emergency(emergency),
        .valid_in(valid_in),
        .cathode(cathode),
        .anode(anode),
        .r(r),
        .g(g),
        .b(b)
    );

    // Clock generator
    initial begin
        clk <= 1'b0;
        forever #5 clk <= ~clk;
    end

    // Reset task
    task reseter;
        reset <= 0;
        @(posedge clk);
        reset <= #1 1;
        @(posedge clk);
        reset <= #1 0;
    endtask

    // Task to drive inputs
    task driver(input logic dir, input logic [2:0] floor, input logic emerg = 0);
        @(posedge clk);
        direction <= #1 dir;
        req_floor <= #1 floor;
        emergency <= #1 emerg;
        valid_in <= #1 1;
        @(posedge clk);
        valid_in <= #1 0;
    endtask

    // Function to decode anode
    function [7:0] anode_decoder(input logic [2:0] floor);
        case(floor)
            3'b000: return 8'b11111110;
            3'b001: return 8'b11111101;
            3'b010: return 8'b11111011;
            3'b011: return 8'b11110111;
            3'b100: return 8'b11101111;
            3'b101: return 8'b11011111;
            3'b110: return 8'b10111111;
            3'b111: return 8'b01111111;
        endcase
    endfunction

    // Function to decode cathode
    function [6:0] cathode_decoder(input logic [2:0] floor);
        case(floor)
            3'b000: return 7'b0000001;
            3'b001: return 7'b1001111;
            3'b010: return 7'b0010010;
            3'b011: return 7'b0000110;
            3'b100: return 7'b1001100;
            3'b101: return 7'b0100100;
            3'b110: return 7'b0100000;
            3'b111: return 7'b0001111;
        endcase
    endfunction

    // Function to predict RGB LEDs based on state
    function [2:0] rgb_decoder(input logic [2:0] state);
        case(state)
            3'd0: return 3'b000; // RESET
            3'd1: return 3'b010; // IDLE
            3'd2: return 3'b001; // MOVING_UP
            3'd3: return 3'b110; // MOVING_DOWN
            3'd4: return 3'b011; // DOOR_OPEN
            3'd5: return 3'b101; // DOOR_CLOSE
            3'd6: return 3'b100; // EMERGENCY
            default: return 3'b000;
        endcase
    endfunction

    // Monitor task
    task monitor;
        logic [7:0] expected_anode;
        logic [6:0] expected_cathode;
        logic [2:0] expected_rgb;
        @(posedge clk);
        expected_anode = anode_decoder(UUT.current_floor);
        expected_cathode = cathode_decoder(UUT.current_floor);
        expected_rgb = rgb_decoder(UUT.current_state);

        if (expected_anode != anode)
            $display("Error-In-Anode: Floor = %d, Expected = %b, Got = %b", UUT.current_floor, expected_anode, anode);
        else
            $display("Anode-Pass: Floor = %d, Got = %b", UUT.current_floor, anode);

        if (expected_cathode != cathode)
            $display("Error-In-Cathode: Floor = %d, Expected = %b, Got = %b", UUT.current_floor, expected_cathode, cathode);
        else
            $display("Cathode-Pass: Floor = %d, Got = %b", UUT.current_floor, cathode);

        if ({r, g, b} != expected_rgb)
            $display("Error-In-RGB: State = %d, Expected = %b, Got = %b", UUT.current_state, expected_rgb, {r, g, b});
        else
            $display("RGB-Pass: State = %d, Got = %b", UUT.current_state, {r, g, b});
    endtask

    // Test sequence
    initial begin
        direction = 0;
        req_floor = 0;
        emergency = 0;
        valid_in = 0;

        reseter;

        $display("Test 1: Requesting floor 3 (up)");
        driver(1, 3'd3, 0);
        repeat(50) begin monitor(); @(posedge clk); end

        $display("Test 2: Requesting floor 1 (down)");
        driver(0, 3'd1, 0);
        repeat(50) begin monitor(); @(posedge clk); end

        $display("Test 3: Triggering emergency");
        driver(1, 3'd4, 1);
        repeat(10) begin monitor(); @(posedge clk); end

        $display("Test 4: Clearing emergency");
        driver(1, 3'd4, 0);
        repeat(20) begin monitor(); @(posedge clk); end

        $display("Test 5: Request floor 5 then floor 2");
        driver(1, 3'd5, 0);
        repeat(50) begin monitor(); @(posedge clk); end
        driver(0, 3'd2, 0);
        repeat(50) begin monitor(); @(posedge clk); end

        $display("Testbench completed.");
        $finish;
    end

endmodule