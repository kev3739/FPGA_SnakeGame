// =============================================================================
// pll_25m.v  --  25 MHz Clock Generator
//
// This module takes the 50 MHz clock from the board and divides it by 2
// to create a 25 MHz clock.
//
// The VGA system uses this 25 MHz clock.
// =============================================================================

module pll_25m (
    input  wire inclk0,   // 50 MHz input clock
    output wire c0,       // 25 MHz output clock
    output wire locked    // always 1 (no real PLL used)
);

reg clk_div;


// Toggle the clock each cycle
// This divides the frequency by 2
always @(posedge inclk0)
    clk_div <= ~clk_div;


// Output signals
assign c0     = clk_div;
assign locked = 1'b1;

endmodule