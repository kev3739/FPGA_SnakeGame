// =============================================================================
// seg7_decoder.v  --  7-Segment Display Decoder
//
// This module converts a number (0–9) into the signals needed to show
// that number on a 7-segment display.
//
// The display on the board is active-low:
// 0 = segment turns ON
// 1 = segment turns OFF
// =============================================================================

module seg7_decoder (
    input  wire [3:0] bcd,   // number to display (0–9)
    output reg  [6:0] seg    // segments {a,b,c,d,e,f,g}
);

always @(*) begin

    case (bcd)

        //        abcdefg   (0 = segment ON)

        4'd0: seg = 7'b1000000;
        4'd1: seg = 7'b1111001;
        4'd2: seg = 7'b0100100;
        4'd3: seg = 7'b0110000;
        4'd4: seg = 7'b0011001;
        4'd5: seg = 7'b0010010;
        4'd6: seg = 7'b0000010;
        4'd7: seg = 7'b1111000;
        4'd8: seg = 7'b0000000;
        4'd9: seg = 7'b0010000;

        default:
            seg = 7'b1111111;   // blank display

    endcase

end

endmodule