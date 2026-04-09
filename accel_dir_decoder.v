// =============================================================================
// accel_dir_decoder.v  --  Tilt to Direction Converter
//
// This module takes X and Y values from the accelerometer and converts
// them into a direction for the snake.
//
// Direction codes:
// 00 = RIGHT
// 01 = UP
// 10 = LEFT
// 11 = DOWN
//
// The module first does a short calibration, then continuously checks
// the tilt and updates the direction.
// =============================================================================

module accel_dir_decoder (
    input  wire        clk,
    input  wire        rst,
    input  wire [15:0] accel_x,   // X axis value
    input  wire [15:0] accel_y,   // Y axis value
    output reg  [1:0]  dir        // direction output
);


// Minimum tilt needed to change direction
localparam signed [15:0] THRESHOLD = 16'sd25;


// Number of samples used for calibration
localparam [6:0] CAL_SAMPLES = 7'd64;


// Calibration storage
reg signed [21:0] sum_x;
reg signed [21:0] sum_y;

reg signed [15:0] offset_x;
reg signed [15:0] offset_y;

reg [6:0] cal_count;
reg       calibrated;


// Treat inputs as signed numbers
wire signed [15:0] sx = accel_x;
wire signed [15:0] sy = accel_y;


// Adjust values using calibration offset
wire signed [15:0] dx = sx - offset_x;
wire signed [15:0] dy = sy - offset_y;


// Absolute values for comparison
wire signed [15:0] abs_dx =
    dx[15] ? (~dx + 16'd1) : dx;

wire signed [15:0] abs_dy =
    dy[15] ? (~dy + 16'd1) : dy;


// Main logic
always @(posedge clk or posedge rst) begin

    if (rst) begin

        sum_x      <= 22'sd0;
        sum_y      <= 22'sd0;

        offset_x   <= 16'sd0;
        offset_y   <= 16'sd0;

        cal_count  <= 7'd0;
        calibrated <= 1'b0;

        dir <= 2'b00;   // start moving right

    end


    // Calibration phase
    else if (!calibrated) begin

        sum_x <= sum_x + sx;
        sum_y <= sum_y + sy;

        if (cal_count == CAL_SAMPLES - 1'b1) begin

            offset_x <= (sum_x + sx) >>> 6;
            offset_y <= (sum_y + sy) >>> 6;

            calibrated <= 1'b1;

        end

        else begin
            cal_count <= cal_count + 1'b1;
        end

    end


    // Normal operation
    else begin

        // If tilt is very small, keep same direction
        if ((abs_dx < THRESHOLD) &&
            (abs_dy < THRESHOLD)) begin

            dir <= dir;

        end


        // X movement
        else if (abs_dx >= abs_dy) begin

            if (dx > 0)
                dir <= 2'b10;   // LEFT
            else
                dir <= 2'b00;   // RIGHT

        end


        // Y movement
        else begin

            if (dy < 0)
                dir <= 2'b01;   // UP
            else
                dir <= 2'b11;   // DOWN

        end

    end

end

endmodule