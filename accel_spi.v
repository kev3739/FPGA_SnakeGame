// =============================================================================
// accel_spi.v  --  Accelerometer SPI Driver
//
// This module communicates with the ADXL345 accelerometer using SPI.
// It sends setup commands once after reset, then continuously reads
// X and Y tilt values from the sensor.
// =============================================================================

module accel_spi (
    input  wire        clk,       // 50 MHz clock
    input  wire        rst,       // reset signal
    output reg         cs_n,      // chip select (active low)
    output reg         sclk,      // SPI clock
    output reg         mosi,      // data sent to sensor
    input  wire        miso,      // data received from sensor
    output reg [15:0]  accel_x,   // X-axis value
    output reg [15:0]  accel_y    // Y-axis value
);


// SPI clock divider
localparam integer DIVIDER = 25;


// Register addresses
localparam [7:0] REG_BW_RATE     = 8'h2C;
localparam [7:0] REG_POWER_CTL   = 8'h2D;
localparam [7:0] REG_DATA_FORMAT = 8'h31;
localparam [7:0] REG_DATAX0      = 8'h32;


// Command bytes
localparam [7:0] CMD_WRITE_BW_RATE     = REG_BW_RATE;
localparam [7:0] CMD_WRITE_POWER_CTL   = REG_POWER_CTL;
localparam [7:0] CMD_WRITE_DATA_FORMAT = REG_DATA_FORMAT;
localparam [7:0] CMD_READ_XY           = 8'hC0 | REG_DATAX0;


// FSM states
localparam [2:0] ST_POWERUP = 3'd0;
localparam [2:0] ST_WRITE1  = 3'd1;
localparam [2:0] ST_GAP1    = 3'd2;
localparam [2:0] ST_WRITE2  = 3'd3;
localparam [2:0] ST_GAP2    = 3'd4;
localparam [2:0] ST_WRITE3  = 3'd5;
localparam [2:0] ST_READ    = 3'd6;
localparam [2:0] ST_GAP3    = 3'd7;


reg [2:0]  state;
reg [23:0] wait_cnt;
reg [5:0]  div_cnt;
reg        spi_en;

reg [55:0] tx_shift;
reg [47:0] rx_shift;
reg [5:0]  bits_left;


// Generate SPI timing tick
wire tick = (div_cnt == DIVIDER - 1'b1);


// SPI engine and state machine
always @(posedge clk or posedge rst) begin

    if (rst) begin

        state     <= ST_POWERUP;
        wait_cnt  <= 24'd0;
        div_cnt   <= 6'd0;

        spi_en    <= 1'b0;
        cs_n      <= 1'b1;
        sclk      <= 1'b1;
        mosi      <= 1'b1;

        tx_shift  <= 56'd0;
        rx_shift  <= 48'd0;
        bits_left <= 6'd0;

        accel_x   <= 16'd0;
        accel_y   <= 16'd0;

    end

    else begin


        // SPI clock control
        if (!spi_en) begin

            div_cnt <= 6'd0;
            sclk    <= 1'b1;

        end

        else if (tick) begin

            div_cnt <= 6'd0;

            if (sclk) begin

                // send next bit
                sclk <= 1'b0;
                mosi <= tx_shift[55];

            end

            else begin

                // read incoming bit
                sclk     <= 1'b1;
                tx_shift <= {tx_shift[54:0], 1'b1};
                rx_shift <= {rx_shift[46:0], miso};

                if (bits_left != 0)
                    bits_left <= bits_left - 1'b1;

            end

        end

        else begin
            div_cnt <= div_cnt + 1'b1;
        end



        // State machine
        case (state)


            // Wait after reset
            ST_POWERUP: begin

                cs_n   <= 1'b1;
                spi_en <= 1'b0;

                if (wait_cnt < 24'd2_500_000) begin
                    wait_cnt <= wait_cnt + 1'b1;
                end

                else begin

                    wait_cnt <= 24'd0;

                    state  <= ST_WRITE1;
                    cs_n   <= 1'b0;
                    spi_en <= 1'b1;

                    tx_shift  <= {CMD_WRITE_DATA_FORMAT, 8'h08, 40'd0};
                    bits_left <= 6'd16;

                    mosi <= CMD_WRITE_DATA_FORMAT[7];

                end

            end



            // Finish first write
            ST_WRITE1: begin

                if (spi_en && sclk && tick && (bits_left == 0)) begin

                    cs_n     <= 1'b1;
                    spi_en   <= 1'b0;

                    wait_cnt <= 24'd0;
                    state    <= ST_GAP1;

                end

            end



            // Small delay
            ST_GAP1: begin

                if (wait_cnt < 24'd10_000)
                    wait_cnt <= wait_cnt + 1'b1;

                else begin

                    wait_cnt <= 24'd0;

                    state  <= ST_WRITE2;
                    cs_n   <= 1'b0;
                    spi_en <= 1'b1;

                    tx_shift  <= {CMD_WRITE_BW_RATE, 8'h0A, 40'd0};
                    bits_left <= 6'd16;

                    mosi <= CMD_WRITE_BW_RATE[7];

                end

            end



            ST_WRITE2: begin

                if (spi_en && sclk && tick && (bits_left == 0)) begin

                    cs_n     <= 1'b1;
                    spi_en   <= 1'b0;

                    wait_cnt <= 24'd0;
                    state    <= ST_GAP2;

                end

            end



            ST_GAP2: begin

                if (wait_cnt < 24'd10_000)
                    wait_cnt <= wait_cnt + 1'b1;

                else begin

                    wait_cnt <= 24'd0;

                    state  <= ST_WRITE3;
                    cs_n   <= 1'b0;
                    spi_en <= 1'b1;

                    tx_shift  <= {CMD_WRITE_POWER_CTL, 8'h08, 40'd0};
                    bits_left <= 6'd16;

                    mosi <= CMD_WRITE_POWER_CTL[7];

                end

            end



            ST_WRITE3: begin

                if (spi_en && sclk && tick && (bits_left == 0)) begin

                    cs_n     <= 1'b1;
                    spi_en   <= 1'b0;

                    wait_cnt <= 24'd0;
                    state    <= ST_GAP3;

                end

            end



            // Delay between reads
            ST_GAP3: begin

                if (wait_cnt < 24'd50_000)
                    wait_cnt <= wait_cnt + 1'b1;

                else begin

                    wait_cnt <= 24'd0;

                    state  <= ST_READ;
                    cs_n   <= 1'b0;
                    spi_en <= 1'b1;

                    tx_shift  <= {CMD_READ_XY, 48'd0};
                    rx_shift  <= 48'd0;

                    bits_left <= 6'd56;

                    mosi <= CMD_READ_XY[7];

                end

            end



            // Read sensor data
            ST_READ: begin

                if (spi_en && sclk && tick && (bits_left == 0)) begin

                    cs_n   <= 1'b1;
                    spi_en <= 1'b0;

                    accel_x <= {rx_shift[39:32], rx_shift[47:40]};
                    accel_y <= {rx_shift[23:16], rx_shift[31:24]};

                    wait_cnt <= 24'd0;
                    state    <= ST_GAP3;

                end

            end



            default:
                state <= ST_POWERUP;

        endcase

    end

end

endmodule