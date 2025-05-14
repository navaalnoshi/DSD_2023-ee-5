`timescale 1ns / 1ps

module elevator #(
    parameter COUNT_20S = 10_00_000_000,
    parameter COUNT_1S  = 200_000_000
)(
    input  logic        direction,
    input  logic [2:0]  req_floor,
    input  logic        clk,
    input  logic        reset,
    input  logic        emergency,
    input  logic        valid_in,

    output logic [6:0]  cathode,
    output logic [7:0]  anode,
    output logic r,
    output logic g,
    output logic b
);

logic enable_20s, enable_1s;
logic [2:0] floor_to_go;
logic [30:0] counter;
logic [30:0] counter_1;
logic counting, counting_1;

logic call_up [7:0];
logic call_down [7:0];
logic calls [7:0];
logic floor_increment, floor_decrement;
logic nearest_floor_enable;
logic [2:0] current_floor;
logic one_up_req_completed, one_down_req_completed;
logic [2:0] nearest_floor;
logic [2:0] max_req, min_req;
logic up, down;

always_ff @(posedge clk or posedge reset) begin
    if (reset)
        call_up <= '{default: 1'b0};
    else if (valid_in && direction && (current_floor < req_floor))
        call_up[req_floor] <= 1'b1;
    else if (one_up_req_completed)
        call_up[current_floor] <= 1'b0;
end

always_ff @(posedge clk or posedge reset) begin
    if (reset)
        call_down <= '{default: 1'b0};
    else if (valid_in && !direction && (current_floor > req_floor))
        call_down[req_floor] <= 1'b1;
    else if (one_down_req_completed)
        call_down[current_floor] <= 1'b0;
end

always_ff @(posedge clk or posedge reset) begin
    if (reset)
        calls <= '{default: 1'b0};
    else if (valid_in)
        calls[req_floor] <= 1'b1;
    else if (one_up_req_completed || one_down_req_completed)
        calls[current_floor] <= 1'b0;
end

always_ff @(posedge clk or posedge reset) begin
    if (reset)
        current_floor <= 3'd0;
    else if (floor_increment && enable_1s)
        current_floor <= current_floor + 1;
    else if (floor_decrement && enable_1s)
        current_floor <= current_floor - 1;
end

always_ff @(posedge clk or posedge reset) begin
    if (reset)
        floor_to_go <= 3'd0;
    else if (nearest_floor_enable)
        floor_to_go <= nearest_floor;
end

always_comb begin
    max_req = 0;
    min_req = 7;
    nearest_floor = current_floor;
    up = 0;
    down = 0;

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
    if (max_req > current_floor)
        up = 1;
    else if (min_req < current_floor)
        down = 1;

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
            up = 1;
        else if (nearest_floor < current_floor)
            down = 1;
    end
end

typedef enum logic [2:0] {
    RESET,
    IDLE,
    MOVING_UP,
    MOVING_DOWN,
    DOOR_OPEN,
    DOOR_CLOSE,
    EMERGENCY
} state_t;

state_t current_state, next_state;

always_ff @(posedge clk or posedge reset) begin
    if (reset)
        current_state <= RESET;
    else
        current_state <= next_state;
end

always_comb begin
    next_state = current_state;
    floor_increment = 0;
    floor_decrement = 0;
    nearest_floor_enable = 0;
    one_up_req_completed = 0;
    one_down_req_completed = 0;
    r = 0;
    g = 0;
    b = 0;

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
            next_state = IDLE;
        end

        IDLE: begin
            nearest_floor_enable = 1;
            g = 1;
            if (emergency) begin
                next_state = EMERGENCY;
                g = 0;
            end else if (current_floor < floor_to_go) begin
                next_state = MOVING_UP;
                g = 0;
            end else if (current_floor > floor_to_go) begin
                next_state = MOVING_DOWN;
                g = 0;
            end
        end

        MOVING_UP: begin
            b = 1;
            if (emergency) begin
                next_state = EMERGENCY;
                b = 0;
            end else if (!(current_floor == floor_to_go || call_up[current_floor])) begin
                floor_increment = 1;
                b = 1;
            end else begin
                one_up_req_completed = 1;
                b = 0;
                next_state = DOOR_OPEN;
            end
        end

        MOVING_DOWN: begin
            r = 1;
            g = 1;
            if (emergency) begin
                next_state = EMERGENCY;
                r = 0;
                g = 0;
            end else if (!(current_floor == floor_to_go ||  call_down[current_floor])) begin
                floor_decrement = 1;
                r = 1;
                g = 1;
            end else begin
                one_down_req_completed = 1;
                next_state = DOOR_OPEN;
                r = 0;
                g = 0;
            end
        end

        DOOR_OPEN: begin
            g = 1;
            b = 1;
            if (emergency) begin
                next_state = EMERGENCY;
                g = 0;
                b = 0;
            end else if (enable_1s) begin
                next_state = DOOR_CLOSE;
                g = 0;
                b = 0;
            end
        end

        DOOR_CLOSE: begin
            r = 1;
            b = 1;
            nearest_floor_enable = 1;
            if (emergency) begin
                next_state = EMERGENCY;
                r = 0;
                b = 0;
            end else if (enable_20s) begin
                next_state = IDLE;
                r = 0;
                b = 0;
            end
        end

        EMERGENCY: begin
            r = 1;
            if (!emergency) begin
                r = 0;
                next_state = IDLE;
            end
        end
    endcase
end

always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
        counter <= 0;
        enable_20s <= 0;
        counting <= 0;
    end else begin
        if (current_state == DOOR_CLOSE)
            counting <= 1;
        else begin
            counting <= 0;
            counter <= 0;
        end

        if (counting) begin
            if (counter == COUNT_20S - 1) begin
                enable_20s <= 1;
                counter <= 0;
            end else begin
                counter <= counter + 1;
                enable_20s <= 0;
            end
        end else
            enable_20s <= 0;
    end
end

always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
        counter_1 <= 0;
        enable_1s <= 0;
        counting_1 <= 0;
    end else begin
        if (current_state == MOVING_UP || current_state == MOVING_DOWN || current_state == DOOR_OPEN)
            counting_1 <= 1;
        else begin
            counting_1 <= 0;
            counter_1 <= 0;
        end

        if (counting_1) begin
            if (counter_1 == COUNT_1S - 1) begin
                enable_1s <= 1;
                counter_1 <= 0;
                counting_1 <= 0;
            end else begin
                counter_1 <= counter_1 + 1;
                enable_1s <= 0;
            end
        end else
            enable_1s <= 0;
    end
end

always_comb begin
    case (current_floor)
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

always_comb begin
    case (current_floor)
        3'b000 : cathode = 7'b0000001;
        3'b001 : cathode = 7'b1001111;
        3'b010 : cathode = 7'b0010010;
        3'b011 : cathode = 7'b0000110;
        3'b100 : cathode = 7'b1001100;
        3'b101 : cathode = 7'b0100100;
        3'b110 : cathode = 7'b0100000;
        3'b111 : cathode = 7'b0001111;
    endcase
end

endmodule
