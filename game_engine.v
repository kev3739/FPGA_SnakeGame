// =============================================================================
// game_engine.v  --  Snake Game Logic and Drawing
//
// This module controls the game behavior and what gets drawn on the screen.
// It handles movement, collisions, food, score, and pixel colors.
// =============================================================================

`define TILE 10'd20   // each tile is 20×20 pixels

module game_engine (
    input  wire        clk,        // 25 MHz clock
    input  wire        rst,        // reset signal
    input  wire        animate,    // pulse once per frame
    input  wire [27:0] speed_div,  // controls how fast the snake moves
    input  wire [1:0]  dir,        // direction input
    input  wire [9:0]  x,          // current pixel column
    input  wire [9:0]  y,          // current pixel row
    input  wire        de,         // display enable
    output reg  [3:0]  r,
    output reg  [3:0]  g,
    output reg  [3:0]  b,
    output wire [7:0]  score
);

localparam MAX_LEN = 32;   // maximum snake size


// Generate game ticks
// The snake only moves when a tick happens
reg [27:0] tick_cnt;
reg        game_tick;

always @(posedge clk) begin
    if (rst) begin
        tick_cnt  <= 0;
        game_tick <= 0;
    end else begin
        game_tick <= 0;

        if (tick_cnt >= speed_div - 1) begin
            tick_cnt  <= 0;
            game_tick <= 1;
        end else begin
            tick_cnt <= tick_cnt + 1;
        end
    end
end


// Store current direction
// Prevent the snake from reversing directly
reg [1:0] cur_dir;

always @(posedge clk) begin
    if (rst)
        cur_dir <= 2'b00;   // start moving right
    else if (game_tick) begin
        if (dir != (cur_dir ^ 2'b10))
            cur_dir <= dir;
    end
end


// Snake head position
reg [9:0] head_x, head_y;

always @(posedge clk) begin
    if (rst) begin
        head_x <= 10'd300;
        head_y <= 10'd240;
    end
    else if (game_tick && (state == PLAYING)) begin
        case (cur_dir)
            2'b00: head_x <= head_x + `TILE;
            2'b01: head_y <= head_y - `TILE;
            2'b10: head_x <= head_x - `TILE;
            2'b11: head_y <= head_y + `TILE;
        endcase
    end
end


// Snake body storage
wire [319:0] seg_x_flat;
wire [319:0] seg_y_flat;
wire [5:0]   body_length;

snake_body body_inst (
    .clk        (clk),
    .rst        (rst),
    .tick       (game_tick & (state == PLAYING)),
    .grow       (grow),
    .head_x     (head_x),
    .head_y     (head_y),
    .seg_x_flat (seg_x_flat),
    .seg_y_flat (seg_y_flat),
    .length     (body_length)
);


// Food generator
wire [9:0] food_x, food_y;
reg        food_next;

lfsr_food food_inst (
    .clk    (clk),
    .rst    (rst),
    .next   (food_next),
    .food_x (food_x),
    .food_y (food_y)
);


// Score register
reg [7:0] score_r;
assign score = score_r;


// Game states
localparam IDLE      = 2'd0;
localparam PLAYING   = 2'd1;
localparam GAME_OVER = 2'd2;

reg [1:0] state;


// Wall collision check
wire wall_hit =
       (head_x < 10'd20)  || (head_x > 10'd600) ||
       (head_y < 10'd20)  || (head_y > 10'd440);


// Self collision check
reg  self_hit;
integer ci;

always @(*) begin
    self_hit = 1'b0;

    for (ci = 1; ci < MAX_LEN; ci = ci + 1) begin
        if (ci < body_length) begin
            if ((head_x == seg_x_flat[ci*10 +: 10]) &&
                (head_y == seg_y_flat[ci*10 +: 10]))
                self_hit = 1'b1;
        end
    end
end


// Check if food is eaten
wire food_eaten =
    (head_x == food_x) &&
    (head_y == food_y);


// Grow signal
wire grow =
    game_tick &
    (state == PLAYING) &
    food_eaten &
    ~(wall_hit | self_hit);


// State machine
always @(posedge clk) begin
    if (rst) begin
        state     <= IDLE;
        score_r   <= 8'd0;
        food_next <= 1'b0;
    end
    else begin

        food_next <= 1'b0;

        case (state)

            IDLE: begin
                if (game_tick)
                    state <= PLAYING;
            end

            PLAYING: begin
                if (game_tick) begin

                    if (wall_hit || self_hit) begin
                        state <= GAME_OVER;
                    end

                    else if (food_eaten) begin
                        score_r   <= score_r + 1;
                        food_next <= 1'b1;
                    end

                end
            end

            GAME_OVER: begin
                // wait for reset
            end

            default:
                state <= IDLE;

        endcase
    end
end


// Check if pixel is inside a tile
function in_tile;
    input [9:0] px, py, tx, ty;
    begin
        in_tile =
            (px >= tx) &&
            (px < tx + `TILE) &&
            (py >= ty) &&
            (py < ty + `TILE);
    end
endfunction


// Pixel checks
wire is_head   = in_tile(x, y, head_x, head_y);
wire is_food   = in_tile(x, y, food_x, food_y);

wire is_border =
       (x < 10'd20)  || (x >= 10'd620) ||
       (y < 10'd20)  || (y >= 10'd460);


// Body pixel detection
wire [MAX_LEN-1:0] body_hit_vec;

genvar gi;

generate
    for (gi = 0; gi < MAX_LEN; gi = gi + 1) begin : body_cmp

        assign body_hit_vec[gi] =
            (gi < body_length) &
            in_tile(
                x,
                y,
                seg_x_flat[gi*10 +: 10],
                seg_y_flat[gi*10 +: 10]
            );

    end
endgenerate

wire is_body = |body_hit_vec;


// Pixel colors
always @(posedge clk) begin

    if (!de) begin
        r <= 4'h0;
        g <= 4'h0;
        b <= 4'h0;
    end

    else begin

        case (state)

            GAME_OVER: begin
                r <= 4'hF;
                g <= 4'h0;
                b <= 4'h0;
            end

            default: begin

                if (is_head) begin
                    r <= 4'h0; g <= 4'hF; b <= 4'h2;
                end

                else if (is_body) begin
                    r <= 4'h0; g <= 4'h8; b <= 4'h1;
                end

                else if (is_food) begin
                    r <= 4'hF; g <= 4'h6; b <= 4'h0;
                end

                else if (is_border) begin
                    r <= 4'h0; g <= 4'h4; b <= 4'h9;
                end

                else begin
                    r <= 4'h1; g <= 4'h1; b <= 4'h1;
                end

            end

        endcase

    end

end

endmodule