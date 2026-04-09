// =============================================================================
// snake_top.v  --  Top-Level Module
//
// This module connects all the other modules together.
//
// Board used: DE10-Lite
// =============================================================================

module snake_top (
    input  wire        MAX10_CLK1_50,   // Main 50 MHz clock from the board
    input  wire        ADC_CLK_10,      // 10 MHz clock used for the ADC

    // VGA outputs
    output wire [3:0]  VGA_R,
    output wire [3:0]  VGA_G,
    output wire [3:0]  VGA_B,
    output wire        VGA_HS,
    output wire        VGA_VS,

    // 7-segment displays
    output wire [6:0]  HEX0,   // Score ones digit
    output wire [6:0]  HEX1,   // Score tens digit
    output wire [6:0]  HEX2,
    output wire [6:0]  HEX3,
    output wire [6:0]  HEX4,
    output wire [6:0]  HEX5,

    input  wire [1:0]  KEY,    // KEY[0] is reset button
    input  wire [9:0]  SW,     // Switch input (not really used)

    // Accelerometer SPI signals
    output wire        GSENSOR_CS_N,
    output wire        GSENSOR_SCLK,
    output wire        GSENSOR_SDI,
    input  wire        GSENSOR_SDO
);

// Create a 25 MHz clock from the 50 MHz clock
wire clk_25;
wire pll_locked;

pll_25m pll_inst (
    .inclk0 (MAX10_CLK1_50),
    .c0     (clk_25),
    .locked (pll_locked)
);

// Reset signal
// The reset happens when the button is pressed
wire rst = ~KEY[0] | ~pll_locked;


// VGA timing generator
// This tells us the current pixel position on the screen
wire [9:0] vga_x, vga_y;
wire       vga_de, vga_animate;

vga_sync vga_sync_inst (
    .clk     (clk_25),
    .rst     (rst),
    .hsync   (VGA_HS),
    .vsync   (VGA_VS),
    .x       (vga_x),
    .y       (vga_y),
    .de      (vga_de),
    .animate (vga_animate)
);


// Read accelerometer values using SPI
// Gives X and Y tilt values
wire [15:0] accel_x_raw, accel_y_raw;

accel_spi accel_inst (
    .clk     (MAX10_CLK1_50),
    .rst     (rst),
    .cs_n    (GSENSOR_CS_N),
    .sclk    (GSENSOR_SCLK),
    .mosi    (GSENSOR_SDI),
    .miso    (GSENSOR_SDO),
    .accel_x (accel_x_raw),
    .accel_y (accel_y_raw)
);


// Convert tilt into a direction
// Example: right, up, left, or down
wire [1:0] accel_dir;

accel_dir_decoder dir_dec (
    .clk     (MAX10_CLK1_50),
    .rst     (rst),
    .accel_x (accel_x_raw),
    .accel_y (accel_y_raw),
    .dir     (accel_dir)
);


// Read temperature from the chip using ADC
wire [11:0] adc_data;
wire        adc_done;

adc_controller adc_inst (
    .clk      (MAX10_CLK1_50),
    .adc_clk  (ADC_CLK_10),
    .rst      (rst),
    .sw_speed (SW[0]),
    .adc_data (adc_data),
    .adc_done (adc_done)
);


// Convert temperature into game speed
// Higher temperature = faster snake
wire [27:0] speed_div;

adc_speed_ctrl adc_spd (
    .clk       (MAX10_CLK1_50),
    .rst       (rst),
    .adc_data  (adc_data),
    .adc_done  (adc_done),
    .speed_div (speed_div)
);


// Main game logic
// Handles snake movement, collisions, and drawing pixels
wire [3:0] r_out, g_out, b_out;
wire [7:0] score;

game_engine game_inst (
    .clk       (clk_25),
    .rst       (rst),
    .animate   (vga_animate),
    .speed_div (speed_div),
    .dir       (accel_dir),
    .x         (vga_x),
    .y         (vga_y),
    .de        (vga_de),
    .r         (r_out),
    .g         (g_out),
    .b         (b_out),
    .score     (score)
);


// Send colors to VGA output
assign VGA_R = r_out;
assign VGA_G = g_out;
assign VGA_B = b_out;


// Convert score into digits for display
wire [3:0] bcd_ones = score % 10;
wire [3:0] bcd_tens = (score / 10) % 10;

seg7_decoder seg0 (.bcd(bcd_ones), .seg(HEX0));
seg7_decoder seg1 (.bcd(bcd_tens), .seg(HEX1));


// Turn off unused displays
assign HEX2 = 7'b1111111;
assign HEX3 = 7'b1111111;
assign HEX4 = 7'b1111111;
assign HEX5 = 7'b1111111;

endmodule