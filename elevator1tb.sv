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

    // Function to decode anode based on current floor
    function [7:0] anode_decoder(input logic [2:0] floor);
        logic [7:0] anode_out;
        case(floor)
            3'b000: anode_out = 8'b11111110;
            3'b001: anode_out = 8'b11111101;
            3'b010: anode_out = 8'b11111011;
            3'b011: anode_out = 8'b11110111;
            3'b100: anode_out = 8'b11101111;
            3'b101: anode_out = 8'b11011111;
            3'b110: anode_out = 8'b10111111;
            3'b111: anode_out = 8'b01111111;
        endcase
        return anode_out;
    endfunction

    // Function to decode cathode based on current floor
    function [6:0] cathode_decoder(input logic [2:0] floor);
        logic [6:0] cathode_out;
        case(floor)
            3'b000: cathode_out = 7'b0000001;
            3'b001: cathode_out = 7'b1001111;
            3'b010: cathode_out = 7'b0010010;
            3'b011: cathode_out = 7'b0000110;
            3'b100: cathode_out = 7'b1001100;
            3'b101: cathode_out = 7'b0100100;
            3'b110: cathode_out = 7'b0100000;
            3'b111: cathode_out = 7'b0001111;
        endcase
        return cathode_out;
    endfunction

    // Function to predict RGB LEDs based on state
    function [2:0] rgb_decoder(input logic [2:0] state);
        logic r_exp, g_exp, b_exp;
        r_exp = 0;
        g_exp = 0;
        b_exp = 0;
        case(state)
            3'd0: begin // RESET
                r_exp = 0; g_exp = 0; b_exp = 0;
            end
            3'd1: begin // IDLE
                r_exp = 0; g_exp = 1; b_exp = 0;
            end
            3'd2: begin // MOVING_UP
                r_exp = 0; g_exp = 0; b_exp = 1;
            end
            3'd3: begin // MOVING_DOWN
                r_exp = 1; g_exp = 1; b_exp = 0;
            end
            3'd4: begin // DOOR_OPEN
                r_exp = 0; g_exp = 1; b_exp = 1;
            end
            3'd5: begin // DOOR_CLOSE
                r_exp = 1; g_exp = 0; b_exp = 1;
            end
            3'd6: begin // EMERGENCY
                r_exp = 1; g_exp = 0; b_exp = 0;
            end
            default: begin
                r_exp = 0; g_exp = 0; b_exp = 0;
            end
        endcase
        return {r_exp, g_exp, b_exp};
    endfunction

    // Variables to track expected state and floor
    logic [2:0] expected_state;
    logic [2:0] expected_floor;
    logic [2:0] expected_floor_to_go;
    logic [7:0] call_up_tracker [8];
    logic [7:0] call_down_tracker [8];
    logic [7:0] calls_tracker [8];
    logic counting_1s, counting_20s;
    logic [31:0] counter_1s, counter_20s;
    const logic [31:0] COUNT_1S = 10;
    const logic [31:0] COUNT_20S = 20;
    logic enable_1s, enable_20s;
    logic floor_increment, floor_decrement;
    logic nearest_floor_enable;
    logic one_up_req_completed, one_down_req_completed;

    // Track call_up, call_down, and calls
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            call_up_tracker <= '{default: 1'b0};
        end else if (valid_in && direction && (expected_floor < req_floor)) begin
            call_up_tracker[req_floor] <= 1'b1;
        end else if (one_up_req_completed) begin
            call_up_tracker[expected_floor] <= 1'b0;
        end
    end

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            call_down_tracker <= '{default: 1'b0};
        end else if (valid_in && !direction && (expected_floor > req_floor)) begin
            call_down_tracker[req_floor] <= 1'b1;
        end else if (one_down_req_completed) begin
            call_down_tracker[expected_floor] <= 1'b0;
        end
    end

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            calls_tracker <= '{default: 1'b0};
        end else if (valid_in) begin
            calls_tracker[req_floor] <= 1'b1;
        end else if (one_up_req_completed || one_down_req_completed) begin
            calls_tracker[expected_floor] <= 1'b0;
        end
    end

    // Track expected floor
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            expected_floor <= 3'd0;
        end else if (floor_increment && enable_1s) begin
            expected_floor <= expected_floor + 1;
        end else if (floor_decrement && enable_1s) begin
            expected_floor <= expected_floor - 1;
        end
    end

    // Track expected floor_to_go
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            expected_floor_to_go <= 3'd0;
        end else if (nearest_floor_enable) begin
            expected_floor_to_go <= expected_nearest_floor();
        end
    end

    // Function to calculate nearest floor (mimics module logic)
    function [2:0] expected_nearest_floor;
        logic [2:0] max_req, min_req, nearest;
        logic up, down;
        max_req = 0;
        min_req = 7;
        nearest = expected_floor;
        up = 0;
        down = 0;

        // Find max_req (highest floor with call_up)
        if (call_up_tracker[7]) max_req = 7;
        else if (call_up_tracker[6]) max_req = 6;
        else if (call_up_tracker[5]) max_req = 5;
        else if (call_up_tracker[4]) max_req = 4;
        else if (call_up_tracker[3]) max_req = 3;
        else if (call_up_tracker[2]) max_req = 2;
        else if (call_up_tracker[1]) max_req = 1;
        else if (call_up_tracker[0]) max_req = 0;

        // Find min_req (lowest floor with call_down)
        if (call_down_tracker[0]) min_req = 0;
        else if (call_down_tracker[1]) min_req = 1;
        else if (call_down_tracker[2]) min_req = 2;
        else if (call_down_tracker[3]) min_req = 3;
        else if (call_down_tracker[4]) min_req = 4;
        else if (call_down_tracker[5]) min_req = 5;
        else if (call_down_tracker[6]) min_req = 6;
        else if (call_down_tracker[7]) min_req = 7;

        // Determine direction
        if (max_req > expected_floor)
            up = 1;
        else if (min_req < expected_floor)
            down = 1;

        // Find nearest_floor based on direction
        if (up) begin
            if (expected_floor <= 6 && call_up_tracker[expected_floor + 3'd1]) nearest = expected_floor + 3'd1;
            else if (expected_floor <= 5 && call_up_tracker[expected_floor + 3'd2]) nearest = expected_floor + 3'd2;
            else if (expected_floor <= 4 && call_up_tracker[expected_floor + 3'd3]) nearest = expected_floor + 3'd3;
            else if (expected_floor <= 3 && call_up_tracker[expected_floor + 3'd4]) nearest = expected_floor + 3'd4;
            else if (expected_floor <= 2 && call_up_tracker[expected_floor + 3'd5]) nearest = expected_floor + 3'd5;
            else if (expected_floor <= 1 && call_up_tracker[expected_floor + 3'd6]) nearest = expected_floor + 3'd6;
            else if (expected_floor == 0 && call_up_tracker[expected_floor + 3'd7]) nearest = expected_floor + 3'd7;
        end else if (down) begin
            if (expected_floor >= 1 && call_down_tracker[expected_floor - 3'd1]) nearest = expected_floor - 3'd1;
            else if (expected_floor >= 2 && call_down_tracker[expected_floor - 3'd2]) nearest = expected_floor - 3'd2;
            else if (expected_floor >= 3 && call_down_tracker[expected_floor - 3'd3]) nearest = expected_floor - 3'd3;
            else if (expected_floor >= 4 && call_down_tracker[expected_floor - 3'd4]) nearest = expected_floor - 3'd4;
            else if (expected_floor >= 5 && call_down_tracker[expected_floor - 3'd5]) nearest = expected_floor - 3'd5;
            else if (expected_floor >= 6 && call_down_tracker[expected_floor - 3'd6]) nearest = expected_floor - 3'd6;
            else if (expected_floor == 7 && call_down_tracker[expected_floor - 3'd7]) nearest = expected_floor - 3'd7;
        end else begin
            if (calls_tracker[0]) nearest = 0;
            else if (calls_tracker[1]) nearest = 1;
            else if (calls_tracker[2]) nearest = 2;
            else if (calls_tracker[3]) nearest = 3;
            else if (calls_tracker[4]) nearest = 4;
            else if (calls_tracker[5]) nearest = 5;
            else if (calls_tracker[6]) nearest = 6;
            else if (calls_tracker[7]) nearest = 7;
        end
        return nearest;
    endfunction

    // State machine for tracking expected state
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            expected_state <= 0; // RESET
        end else begin
            case (expected_state)
                0: begin // RESET
                    expected_state <= 1; // IDLE
                end
                1: begin // IDLE
                    if (emergency)
                        expected_state <= 6; // EMERGENCY
                    else if (expected_floor < expected_floor_to_go)
                        expected_state <= 2; // MOVING_UP
                    else if (expected_floor > expected_floor_to_go)
                        expected_state <= 3; // MOVING_DOWN
                end
                2: begin // MOVING_UP
                    if (emergency)
                        expected_state <= 6; // EMERGENCY
                    else if (!(expected_floor == expected_floor_to_go || calls_tracker[expected_floor] || call_up_tracker[expected_floor]))
                        expected_state <= 2; // Stay in MOVING_UP
                    else
                        expected_state <= 4; // DOOR_OPEN
                end
                3: begin // MOVING_DOWN
                    if (emergency)
                        expected_state <= 6; // EMERGENCY
                    else if (!(expected_floor == expected_floor_to_go || calls_tracker[expected_floor] || call_down_tracker[expected_floor]))
                        expected_state <= 3; // Stay in MOVING_DOWN
                    else
                        expected_state <= 4; // DOOR_OPEN
                end
                4: begin // DOOR_OPEN
                    if (emergency)
                        expected_state <= 6; // EMERGENCY
                    else if (enable_1s)
                        expected_state <= 5; // DOOR_CLOSE
                end
                5: begin // DOOR_CLOSE
                    if (emergency)
                        expected_state <= 6; // EMERGENCY
                    else if (enable_20s)
                        expected_state <= 1; // IDLE
                end
                6: begin // EMERGENCY
                    if (!emergency)
                        expected_state <= 1; // IDLE
                end
            endcase
        end
    end

    // Counters for 1s and 20s delays
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            counter_1s <= 0;
            enable_1s <= 0;
            counting_1s <= 0;
        end else begin
            if (expected_state == 2 || expected_state == 3 || expected_state == 4) // MOVING_UP, MOVING_DOWN, or DOOR_OPEN
                counting_1s <= 1;
            else begin
                counting_1s <= 0;
                counter_1s <= 0;
            end

            if (counting_1s) begin
                if (counter_1s == COUNT_1S - 1) begin
                    enable_1s <= 1;
                    counter_1s <= 0;
                    counting_1s <= 0;
                end else begin
                    counter_1s <= counter_1s + 1;
                    enable_1s <= 0;
                end
            end else begin
                enable_1s <= 0;
            end
        end
    end

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            counter_20s <= 0;
            enable_20s <= 0;
            counting_20s <= 0;
        end else begin
            if (expected_state == 5) // DOOR_CLOSE
                counting_20s <= 1;
            else begin
                counting_20s <= 0;
                counter_20s <= 0;
            end

            if (counting_20s) begin
                if (counter_20s == COUNT_20S - 1) begin
                    enable_20s <= 1;
                    counter_20s <= 0;
                end else begin
                    counter_20s <= counter_20s + 1;
                    enable_20s <= 0;
                end
            end else begin
                enable_20s <= 0;
            end
        end
    end

    // Logic to set floor_increment, floor_decrement, etc.
    always_comb begin
        floor_increment = 0;
        floor_decrement = 0;
        nearest_floor_enable = 0;
        one_up_req_completed = 0;
        one_down_req_completed = 0;

        case (expected_state)
            2: begin // MOVING_UP
                if (!(expected_floor == expected_floor_to_go || calls_tracker[expected_floor] || call_up_tracker[expected_floor])) begin
                    floor_increment = 1;
                end else begin
                    one_up_req_completed = 1;
                end
            end
            3: begin // MOVING_DOWN
                if (!(expected_floor == expected_floor_to_go || calls_tracker[expected_floor] || call_down_tracker[expected_floor])) begin
                    floor_decrement = 1;
                end else begin
                    one_down_req_completed = 1;
                end
            end
            5: begin // DOOR_CLOSE
                nearest_floor_enable = 1;
            end
        endcase
    end

    // Monitor task to check outputs
    task monitor;
        logic [7:0] expected_anode;
        logic [6:0] expected_cathode;
        logic [2:0] expected_rgb;
        logic r_exp, g_exp, b_exp;
        @(posedge clk);
        #1; // Small delay to allow signals to settle
        expected_anode = anode_decoder(expected_floor);
        expected_cathode = cathode_decoder(expected_floor);
        expected_rgb = rgb_decoder(expected_state);
        {r_exp, g_exp, b_exp} = expected_rgb;

        $display("Debug: Expected State = %d, Expected Floor = %d, Expected RGB = %b", expected_state, expected_floor, {r_exp, g_exp, b_exp});
        $display("Debug: Actual RGB = %b", {r, g, b});

        // Check anode
        if (expected_anode != anode)
            $display("Error-In-Anode: Expected Floor = %d, Expected Anode Output = %b, Got = %b", expected_floor, expected_anode, anode);
        else
            $display("Anode-Pass: Expected Floor = %d, Got = %b", expected_floor, anode);

        // Check cathode
        if (expected_cathode != cathode)
            $display("Error-In-Cathode: Expected Floor = %d, Expected Cathode Output = %b, Got = %b", expected_floor, expected_cathode, cathode);
        else
            $display("Cathode-Pass: Expected Floor = %d, Got = %b", expected_floor, cathode);

        // Check RGB LEDs
        if ({r, g, b} != {r_exp, g_exp, b_exp})
            $display("Error-In-RGB: Expected State = %d, Expected RGB = %b, Got = %b", expected_state, {r_exp, g_exp, b_exp}, {r, g, b});
        else
            $display("RGB-Pass: Expected State = %d, Got = %b", expected_state, {r, g, b});
    endtask

    // Test sequence
    initial begin
        // Initialize inputs
        direction = 0;
        req_floor = 0;
        emergency = 0;
        valid_in = 0;

        // Reset the module
        reseter;

        // Test 1: Request floor 3 (up) from floor 0
        $display("Test 1: Requesting floor 3 (up)");
        driver(1, 3'd3, 0);  // direction = 1 (up), req_floor = 3
        repeat(50) begin
            monitor();
            @(posedge clk);
        end

        // Test 2: Request floor 1 (down) from floor 3
        $display("Test 2: Requesting floor 1 (down)");
        driver(0, 3'd1, 0);  // direction = 0 (down), req_floor = 1
        repeat(50) begin
            monitor();
            @(posedge clk);
        end

        // Test 3: Trigger emergency mode
        $display("Test 3: Triggering emergency");
        driver(1, 3'd4, 1);  // direction = 1, req_floor = 4, emergency = 1
        repeat(10) begin
            monitor();
            @(posedge clk);
        end

        // Test 4: Clear emergency and return to idle
        $display("Test 4: Clearing emergency");
        driver(1, 3'd4, 0);  // emergency = 0
        repeat(20) begin
            monitor();
            @(posedge clk);
        end

        // Test 5: Multiple requests (floor 5 up, then floor 2 down)
        $display("Test 5: Request floor 5 then floor 2");
        driver(1, 3'd5, 0);  // Request floor 5 (up)
        repeat(50) begin
            monitor();
            @(posedge clk);
        end
        driver(0, 3'd2, 0);  // Request floor 2 (down)
        repeat(50) begin
            monitor();
            @(posedge clk);
        end

        $display("Testbench completed.");
        $finish;
    end

endmodule