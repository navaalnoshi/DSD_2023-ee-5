// Timescale directive for simulation: 1ns time unit, 1ps precision
`timescale 1ns / 1ps

// Elevator module definition with parameterized timing constants
module elevator #(
    parameter COUNT_20S = 100,  // Parameter for 20-second counter
    parameter COUNT_1S  = 1     // Parameter for 1-second counter
)(
    // Input signals
    input  logic        direction,     // Direction of request (1 for up, 0 for down)
    input  logic [2:0]  req_floor,    // Requested floor (0 to 7)
    input  logic        clk,          // Clock input
    input  logic        reset,        // Reset signal
    input  logic        emergency,    // Emergency stop signal
    input  logic        valid_in,     // Valid input signal for requests

    // Output signals
    output logic [6:0]  cathode,      // 7-segment display cathode signals
    output logic [7:0]  anode,        // 7-segment display anode signals
    output logic r,                   // Red LED indicator
    output logic g,                   // Green LED indicator
    output logic b                    // Blue LED indicator
);

// Internal signals
logic enable_20s, enable_1s;          // Enable signals for 20s and 1s timers
logic [2:0] floor_to_go;              // Target floor for the elevator
logic [30:0] counter;                 // Counter for 20s timer
logic [26:0] counter_1;               // Counter for 1s timer
logic counting, counting_1;           // Flags to control counting
logic call_up [7:0];                  // Array to track up requests for each floor
logic call_down [7:0];                // Array to track down requests for each floor
logic calls [7:0];                    // Array to track all calls (up or down)
logic floor_increment, floor_decrement; // Signals to increment/decrement current floor
logic nearest_floor_enable;           // Enable signal for updating nearest floor
logic [2:0] current_floor;           // Current floor of the elevator
logic one_up_req_completed, one_down_req_completed; // Flags for completed requests
logic [2:0] nearest_floor;           // Nearest floor with a request
logic [2:0] max_req, min_req;        // Highest and lowest floors with requests
logic up, down;                      // Direction flags (up or down)

// Sequential logic for handling up requests
always_ff @(posedge clk or posedge reset) begin
    if (reset)
        call_up <= '{default: 1'b0}; // Reset all up requests to 0
    else if (valid_in && direction && (current_floor < req_floor))
        call_up[req_floor] <= 1'b1;  // Set up request for requested floor
    else if (one_up_req_completed)
        call_up[current_floor] <= 1'b0; // Clear up request when completed
end

// Sequential logic for handling down requests
always_ff @(posedge clk or posedge reset) begin
    if (reset)
        call_down <= '{default: 1'b0}; // Reset all down requests to 0
    else if (valid_in && !direction && (current_floor > req_floor))
        call_down[req_floor] <= 1'b1;  // Set down request for requested floor
    else if (one_down_req_completed)
        call_down[current_floor] <= 1'b0; // Clear down request when completed
end

// Sequential logic for tracking all calls (up or down)
always_ff @(posedge clk or posedge reset) begin
    if (reset)
        calls <= '{default: 1'b0};    // Reset all calls to 0
    else if (valid_in)
        calls[req_floor] <= 1'b1;     // Set call for requested floor
    else if (one_up_req_completed || one_down_req_completed)
        calls[current_floor] <= 1'b0; // Clear call when request is completed
end

// Sequential logic for updating current floor
always_ff @(posedge clk or posedge reset) begin
    if (reset)
        current_floor <= 3'd0;        // Reset current floor to 0
    else if (floor_increment && enable_1s)
        current_floor <= current_floor + 1; // Increment floor when enabled
    else if (floor_decrement && enable_1s)
        current_floor <= current_floor - 1; // Decrement floor when enabled
end

// Sequential logic for updating target floor
always_ff @(posedge clk or posedge reset) begin
    if (reset)
        floor_to_go <= 3'd0;          // Reset target floor to 0
    else if (nearest_floor_enable)
        floor_to_go <= nearest_floor; // Update target floor to nearest floor
end

// Combinational logic for determining max/min requests and nearest floor
always_comb begin
   if (reset) begin
    max_req = 0;                     // Default max request to floor 0
    min_req = 7;                     // Default min request to floor 7
    nearest_floor = current_floor;   // Default nearest floor to current floor
    up = 0;                          // Reset up direction
    down = 0;                        // Reset down direction
    end
    // Find max_req (highest floor with call_up)
    if (call_up[7]) max_req = 7;
    else if (call_up[6]) max_req = 6;
    else if (call_up[5]) max_req = 5;
    else if (call_up[4]) max_req = 4;
    else if (call_up[3]) max_req = 3;
    else if (call_up[2]) max_req = 2;
    else if (call_up[1]) max_req = 1;
    else if (call_up[0]) max_req = 0;

    // Find min_req (lowest floor with call_down)
    if (call_down[0]) min_req = 0;
    else if (call_down[1]) min_req = 1;
    else if (call_down[2]) min_req = 2;
    else if (call_down[3]) min_req = 3;
    else if (call_down[4]) min_req = 4;
    else if (call_down[5]) min_req = 5;
    else if (call_down[6]) min_req = 6;
    else if (call_down[7]) min_req = 7;

    // Determine direction
    if (max_req == current_floor)
        up = 0;                      // No up movement if max request is current floor
    else if (min_req == current_floor)
        down = 0;                    // No down movement if min request is current floor

    // Find nearest_floor based on direction
    if (up) begin
        if (current_floor <= 6 && call_up[current_floor + 3'd1]) nearest_floor = current_floor + 3'd1;
        else if (current_floor <= 5 && call_up[current_floor + 3'd2]) nearest_floor = current_floor + 3'd2;
        else if (current_floor <= 4 && call_up[current_floor + 3'd3]) nearest_floor = current_floor + 3'd3;
        else if (current_floor <= 3 && call_up[current_floor + 3'd4]) nearest_floor = current_floor + 3'd4;
        else if (current_floor <= 2 && call_up[current_floor + 3'd5]) nearest_floor = current_floor + 3'd5;
        else if (current_floor <= 1 && call_up[current_floor + 3'd6]) nearest_floor = current_floor + 3'd6;
        else if (current_floor == 0 && call_up[current_floor + 3'd7]) nearest_floor = current_floor + 3'd7;
    end else if (down) begin
        if (current_floor >= 1 && call_down[current_floor - 3'd1]) nearest_floor = current_floor - 3'd1;
        else if (current_floor >= 2 && call_down[current_floor - 3'd2]) nearest_floor = current_floor - 3'd2;
        else if (current_floor >= 3 && call_down[current_floor - 3'd3]) nearest_floor = current_floor - 3'd3;
        else if (current_floor >= 4 && call_down[current_floor - 3'd4]) nearest_floor = current_floor - 3'd4;
        else if (current_floor >= 5 && call_down[current_floor - 3'd5]) nearest_floor = current_floor - 3'd5;
        else if (current_floor >= 6 && call_down[current_floor - 3'd6]) nearest_floor = current_floor - 3'd6;
        else if (current_floor == 7 && call_down[current_floor - 3'd7]) nearest_floor = current_floor - 3'd7;
    end else begin
        // If no up or down direction, find the closest floor with a call
        if (calls[0]) nearest_floor = 0;
        else if (calls[1]) nearest_floor = 1;
        else if (calls[2]) nearest_floor = 2;
        else if (calls[3]) nearest_floor = 3;
        else if (calls[4]) nearest_floor = 4;
        else if (calls[5]) nearest_floor = 5;
        else if (calls[6]) nearest_floor = 6;
        else if (calls[7]) nearest_floor = 7;

        if (nearest_floor > current_floor)
            up = 1;                  // Set up direction if nearest floor is above
        else if (nearest_floor < current_floor)
            down = 1;                // Set down direction if nearest floor is below
    end
end

// State machine enumeration for elevator states
typedef enum logic [2:0] {
    RESET,        // Reset state
    IDLE,         // Idle state, waiting for requests
    MOVING_UP,    // Moving up to a requested floor
    MOVING_DOWN,  // Moving down to a requested floor
    DOOR_OPEN,    // Door open state
    DOOR_CLOSE,   // Door close state
    EMERGENCY     // Emergency stop state
} state_t;

state_t current_state, next_state; // Current and next state variables

// Sequential logic for state transitions
always_ff @(posedge clk or posedge reset) begin
    if (reset)
        current_state <= RESET;    // Reset to RESET state
    else
        current_state <= next_state; // Transition to next state
end

// Combinational logic for state machine and control signals
always_comb begin
    next_state = current_state;     // Default: stay in current state
    floor_increment = 0;            // Default: no floor increment
    floor_decrement = 0;            // Default: no floor decrement
    nearest_floor_enable = 0;       // Default: disable nearest floor update
    one_up_req_completed = 0;       // Default: no up request completed
    one_down_req_completed = 0;     // Default: no down request completed
    r = 0;                          // Default: red LED off
    g = 0;                          // Default: green LED off
    b = 0;                          // Default: blue LED off

    if (reset) begin
        floor_increment = 0;
        floor_decrement = 0;
        nearest_floor_enable = 0;
        one_up_req_completed = 0;
        one_down_req_completed = 0;
        r = 0;
        g = 0;
        b = 0;
    end

    case (current_state)
        RESET: begin
            next_state = IDLE;      // Move to IDLE after reset
        end

        IDLE: begin
            nearest_floor_enable = 1; // Enable nearest floor calculation
            g = 1;                    // Green LED on to indicate idle
            if (emergency) begin
                next_state = EMERGENCY; // Transition to EMERGENCY if triggered
                g = 0;                  // Turn off green LED
            end else if (current_floor < floor_to_go) begin
                next_state = MOVING_UP; // Move up if target floor is above
                g = 0;                  // Turn off green LED
            end else if (current_floor > floor_to_go) begin
                next_state = MOVING_DOWN; // Move down if target floor is below
                g = 0;                    // Turn off green LED
            end
        end

        MOVING_UP: begin
            b = 1;                    // Blue LED on to indicate moving up
            if (emergency) begin
                next_state = EMERGENCY; // Transition to EMERGENCY if triggered
                b = 0;                  // Turn off blue LED
            end else if (!(current_floor == floor_to_go || call_up[current_floor])) begin
                floor_increment = 1;    // Increment floor if not at target
                b = 1;                  // Keep blue LED on
            end else begin
                one_up_req_completed = 1; // Mark up request as completed
                b = 0;                    // Turn off blue LED
                next_state = DOOR_OPEN;   // Open door when target reached
            end
        end

        MOVING_DOWN: begin
            r = 1;                    // Red LED on to indicate moving down
            g = 1;                    // Green LED on to indicate moving down
            if (emergency) begin
                next_state = EMERGENCY; // Transition to EMERGENCY if triggered
                r = 0;                  // Turn off red LED
                g = 0;                  // Turn off green LED
            end else if (!(current_floor == floor_to_go  || call_down[current_floor])) begin
                floor_decrement = 1;    // Decrement floor if not at target
                r = 1;                  // Keep red LED on
                g = 1;                  // Keep green LED on
            end else begin
                one_down_req_completed = 1; // Mark down request as completed
                next_state = DOOR_OPEN;    // Open door when target reached
                r = 0;                     // Turn off red LED
                g = 0;                     // Turn off green LED
            end
        end

        DOOR_OPEN: begin
            g = 1;                    // Green LED on to indicate door open
            b = 1;                    // Blue LED on to indicate door open
            if (emergency) begin
                next_state = EMERGENCY; // Transition to EMERGENCY if triggered
                g = 0;                  // Turn off green LED
                b = 0;                  // Turn off blue LED
            end else if (enable_1s) begin
                next_state = DOOR_CLOSE; // Close door after 1s
                g = 0;                   // Turn off green LED
                b = 0;                   // Turn off blue LED
            end
        end

        DOOR_CLOSE: begin
            r = 1;                    // Red LED on to indicate door closing
            b = 1;                    // Blue LED on to indicate door closing
            nearest_floor_enable = 1; // Enable nearest floor calculation
            if (emergency) begin
                next_state = EMERGENCY; // Transition to EMERGENCY if triggered
                r = 0;                  // Turn off red LED
                b = 0;                  // Turn off blue LED
            end else if (enable_20s) begin
                next_state = IDLE;      // Return to IDLE after 20s
                r = 0;                  // Turn off red LED
                b = 0;                  // Turn off blue LED
            end
        end

        EMERGENCY: begin
            r = 1;                    // Red LED on to indicate emergency
            if (!emergency) begin
                r = 0;                // Turn off red LED
                next_state = IDLE;    // Return to IDLE when emergency cleared
            end
        end
    endcase
end

// Sequential logic for 20-second timer (door close duration)
always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
        counter <= 0;             // Reset counter
        enable_20s <= 0;          // Disable 20s timer
        counting <= 0;            // Stop counting
    end else begin
        if (current_state == DOOR_CLOSE)
            counting <= 1;        // Start counting in DOOR_CLOSE state
        else begin
            counting <= 0;        // Stop counting
            counter <= 0;         // Reset counter
        end

        if (counting) begin
            if (counter == COUNT_20S - 1) begin
                enable_20s <= 1;  // Enable 20s signal when counter reaches limit
                counter <= 0;     // Reset counter
            end else begin
                counter <= counter + 1; // Increment counter
                enable_20s <= 0;        // Keep 20s signal disabled
            end
        end else
            enable_20s <= 0;    // Disable 20s signal when not counting
    end
end

// Sequential logic for 1-second timer (movement and door open duration)
always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
        counter_1 <= 0;       // Reset counter
        enable_1s <= 0;       // Disable 1s timer
        counting_1 <= 0;      // Stop counting
    end else begin
        if (current_state == MOVING_UP || current_state == MOVING_DOWN || current_state == DOOR_OPEN)
            counting_1 <= 1;  // Start counting in movement or door open states
        else begin
            counting_1 <= 0;  // Stop counting
            counter_1 <= 0;   // Reset counter
        end

        if (counting_1) begin
            if (counter_1 == COUNT_1S - 1) begin
                enable_1s <= 1;   // Enable 1s signal when counter reaches limit
                counter_1 <= 0;   // Reset counter
                counting_1 <= 0;  // Stop counting
            end else begin
                counter_1 <= counter_1 + 1; // Increment counter
                enable_1s <= 0;            // Keep 1s signal disabled
            end
        end else
            enable_1s <= 0;     // Disable 1s signal when not counting
    end
end

// Combinational logic for 7-segment display anode control
always_comb begin
    case (current_floor)
        3'b000 : anode = 8'b11111110; // Select floor 0
        3'b001 : anode = 8'b11111101; // Select floor 1
        3'b010 : anode = 8'b11111011; // Select floor 2
        3'b011 : anode = 8'b11110111; // Select floor 3
        3'b100 : anode = 8'b11101111; // Select floor 4
        3'b101 : anode = 8'b11011111; // Select floor 5
        3'b110 : anode = 8'b10111111; // Select floor 6
        3'b111 : anode = 8'b01111111; // Select floor 7
    endcase
end

// Combinational logic for 7-segment display cathode control (digit display)
always_comb begin
    case (current_floor)
        3'b000 : cathode = 7'b0000001; // Display 0
        3'b001 : cathode = 7'b1001111; // Display 1
        3'b010 : cathode = 7'b0010010; // Display 2
        3'b011 : cathode = 7'b0000110; // Display 3
        3'b100 : cathode = 7'b1001100; // Display 4
        3'b101 : cathode = 7'b0100100; // Display 5
        3'b110 : cathode = 7'b0100000; // Display 6
        3'b111 : cathode = 7'b0001111; // Display 7
    endcase
end

endmodule
