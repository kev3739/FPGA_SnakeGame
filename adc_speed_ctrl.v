// =============================================================================
// adc_speed_ctrl.v  --  Temperature to Speed Controller
//
// This module converts the temperature reading from the ADC into a value
// that controls how fast the snake moves.
//
// Higher temperature → faster snake
// Lower temperature  → slower snake
// =============================================================================

module adc_speed_ctrl (
    input  wire        clk,        // system clock
    input  wire        rst,        // reset signal
    input  wire [11:0] adc_data,   // temperature reading
    input  wire        adc_done,   // new reading available
    output reg  [27:0] speed_div   // value used to control game speed
);


// Slowest speed
localparam [27:0] DIV_SLOW = 28'd12_500_000;


// Fastest speed
localparam [27:0] DIV_FAST = 28'd781_250;


// Difference between slow and fast
localparam [27:0] DIV_RANGE = DIV_SLOW - DIV_FAST;


// Update speed when a new ADC value arrives
always @(posedge clk or posedge rst) begin

    if (rst) begin

        // Start at slow speed after reset
        speed_div <= DIV_SLOW;

    end

    else if (adc_done) begin

        // Calculate new speed based on temperature
        speed_div <=
            DIV_SLOW - ((adc_data * DIV_RANGE) >> 12);

    end

end

endmodule