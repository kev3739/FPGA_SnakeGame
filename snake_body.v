// =============================================================================
// snake_body.v  --  Snake Body Storage
//
// This module keeps track of all the snake body segment positions.
// Each segment stores an (x,y) coordinate.
//
// On every game tick:
// - Each segment moves to the position of the segment in front of it
// - The new head position is written into segment 0
// - If grow is true, the snake length increases by one
// =============================================================================

module snake_body (
    input  wire         clk,
    input  wire         rst,
    input  wire         tick,           // move body one step
    input  wire         grow,           // grow snake if food eaten
    input  wire [9:0]   head_x,         // new head position
    input  wire [9:0]   head_y,
    output wire [319:0] seg_x_flat,     // packed X positions
    output wire [319:0] seg_y_flat,     // packed Y positions
    output reg  [5:0]   length          // current snake length
);

localparam MAX_LEN = 32;   // maximum number of segments


// Storage for segment positions
reg [9:0] mem_x [0:MAX_LEN-1];
reg [9:0] mem_y [0:MAX_LEN-1];

integer i;


// Pack segment memory into flat output buses
// This lets other modules read all segment positions
genvar g;

generate
    for (g = 0; g < MAX_LEN; g = g + 1) begin : flatten
        assign seg_x_flat[g*10 +: 10] = mem_x[g];
        assign seg_y_flat[g*10 +: 10] = mem_y[g];
    end
endgenerate


// Update body positions
always @(posedge clk) begin

    if (rst) begin

        // Start with a 3-segment snake
        length <= 6'd3;

        // Initial positions
        mem_x[0] <= 10'd300; mem_y[0] <= 10'd240;
        mem_x[1] <= 10'd280; mem_y[1] <= 10'd240;
        mem_x[2] <= 10'd260; mem_y[2] <= 10'd240;

        // Clear remaining memory
        for (i = 3; i < MAX_LEN; i = i + 1) begin
            mem_x[i] <= 10'd0;
            mem_y[i] <= 10'd0;
        end

    end

    else if (tick) begin

        // Move each segment back one position
        for (i = MAX_LEN-1; i > 0; i = i - 1) begin

            if (i < (grow ? length + 1 : length)) begin
                mem_x[i] <= mem_x[i-1];
                mem_y[i] <= mem_y[i-1];
            end

        end

        // Insert new head position
        mem_x[0] <= head_x;
        mem_y[0] <= head_y;

        // Increase length if growing
        if (grow && length < MAX_LEN)
            length <= length + 1;

    end

end

endmodule