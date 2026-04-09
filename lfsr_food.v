// =============================================================================
// lfsr_food.v  --  Food Position Generator
//
// This module makes a new food position using an LFSR.
// The LFSR keeps changing every clock cycle, and when the snake eats food,
// the current value is used to choose the next food location.
// =============================================================================

module lfsr_food (
    input  wire        clk,
    input  wire        rst,
    input  wire        next,      // update food position when food is eaten
    output reg  [9:0]  food_x,    // food X position
    output reg  [9:0]  food_y     // food Y position
);

localparam TILE  = 10'd20;   // size of one tile
localparam COLS  = 5'd30;    // number of valid columns
localparam ROWS  = 5'd22;    // number of valid rows

// 16-bit LFSR register
reg [15:0] lfsr;


// Update the LFSR every clock cycle
always @(posedge clk) begin
    if (rst)
        lfsr <= 16'hACE1;   // starting seed value
    else
        lfsr <= {1'b0, lfsr[15:1]} ^ (lfsr[0] ? 16'hB400 : 16'h0000);
end


// Use part of the LFSR value to make a random column and row
wire [4:0] rand_col = (lfsr[14:10] % COLS) + 5'd1;
wire [4:0] rand_row = (lfsr[9:5]   % ROWS) + 5'd1;


// Save a new food position when next goes high
always @(posedge clk) begin
    if (rst) begin
        food_x <= 10'd300;
        food_y <= 10'd240;
    end
    else if (next) begin
        food_x <= {5'b0, rand_col} * TILE;
        food_y <= {5'b0, rand_row} * TILE;
    end
end

endmodule