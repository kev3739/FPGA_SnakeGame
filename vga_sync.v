// =============================================================================
// vga_sync.v  --  VGA Timing Generator
//
// This module creates the timing signals for a 640×480 VGA display.
// It keeps track of the current pixel position using two counters:
// one for horizontal pixels and one for vertical lines.
//
// It also generates:
// - hsync and vsync signals
// - x and y pixel positions
// - display enable signal (de)
// - animate pulse once per frame
// =============================================================================

module vga_sync (
    input  wire        clk,      // 25 MHz clock
    input  wire        rst,      // reset signal
    output reg         hsync,    // horizontal sync (active low)
    output reg         vsync,    // vertical sync (active low)
    output wire [9:0]  x,        // current pixel column
    output wire [9:0]  y,        // current pixel row
    output wire        de,       // 1 when drawing visible pixels
    output reg         animate   // pulse once per frame
);

// Horizontal timing values
localparam H_ACTIVE      = 640;   // visible pixels
localparam H_FRONT_PORCH =  16;   // small delay before sync
localparam H_SYNC_WIDTH  =  96;   // sync pulse length
localparam H_BACK_PORCH  =  48;   // delay after sync
localparam H_TOTAL       = H_ACTIVE + H_FRONT_PORCH + H_SYNC_WIDTH + H_BACK_PORCH;

// Vertical timing values
localparam V_ACTIVE      = 480;   // visible lines
localparam V_FRONT_PORCH =  10;
localparam V_SYNC_WIDTH  =   2;
localparam V_BACK_PORCH  =  33;
localparam V_TOTAL       = V_ACTIVE + V_FRONT_PORCH + V_SYNC_WIDTH + V_BACK_PORCH;


// Counters for pixel position
reg [9:0] h_count;   // horizontal counter
reg [9:0] v_count;   // vertical counter


// Count pixels and lines
// When one line finishes, move to the next line
// When the screen finishes, start a new frame
always @(posedge clk) begin
    if (rst) begin
        h_count <= 0;
        v_count <= 0;
        animate <= 0;
    end else begin
        animate <= 0;

        if (h_count == H_TOTAL - 1) begin
            h_count <= 0;

            if (v_count == V_TOTAL - 1) begin
                v_count <= 0;
                animate <= 1;   // signal that a new frame started
            end else begin
                v_count <= v_count + 1;
            end

        end else begin
            h_count <= h_count + 1;
        end
    end
end


// Generate sync signals
// They go low during the sync period
always @(posedge clk) begin
    hsync <= ~((h_count >= (H_ACTIVE + H_FRONT_PORCH)) &&
               (h_count <  (H_ACTIVE + H_FRONT_PORCH + H_SYNC_WIDTH)));

    vsync <= ~((v_count >= (V_ACTIVE + V_FRONT_PORCH)) &&
               (v_count <  (V_ACTIVE + V_FRONT_PORCH + V_SYNC_WIDTH)));
end


// Display enable and pixel coordinates
// de is 1 only when inside the visible screen area
assign de = (h_count < H_ACTIVE) && (v_count < V_ACTIVE);

// Output pixel position
assign x  = (h_count < H_ACTIVE) ? h_count : 10'd0;
assign y  = (v_count < V_ACTIVE) ? v_count : 10'd0;

endmodule