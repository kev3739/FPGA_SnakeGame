// =============================================================================
// clk_div.v  --  Clock Divider
//
// This module makes a slower clock from a faster clock.
// It counts up to a value (divisor) and then flips the output.
//
// The bigger the divisor, the slower the output clock.
// =============================================================================

module clk_div (
    input  wire        clk,        // input clock
    input  wire        rst,        // reset signal
    input  wire [27:0] divisor,    // number of cycles before toggling
    output reg         clk_out     // slower clock output
);

reg [27:0] counter;


// Count clock cycles and toggle output
always @(posedge clk) begin

    if (rst) begin
        counter <= 0;
        clk_out <= 0;
    end

    else begin

        if (counter >= divisor - 1) begin
            counter <= 0;
            clk_out <= ~clk_out;   // flip the output clock
        end

        else begin
            counter <= counter + 1;
        end

    end

end

endmodule