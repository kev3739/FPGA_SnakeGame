// =============================================================================
// adc_controller.v  --  Temperature Sensor Reader
//
// This module reads the internal temperature sensor using the FPGA's built-in
// ADC. It starts a new measurement about every 1 ms and outputs the result.
//
// When a new value is ready:
//   adc_data = temperature reading
//   adc_done = one-cycle pulse
// =============================================================================

module adc_controller (
    input  wire        clk,        // 50 MHz system clock
    input  wire        adc_clk,    // 10 MHz ADC clock input
    input  wire        rst,        // reset signal
    input  wire        sw_speed,   // not used
    output reg  [11:0] adc_data,   // temperature value
    output reg         adc_done    // new data ready signal
);


// Pass the ADC clock through a PLL
wire adc_pll_c0;
wire adc_pll_locked;

adc_pll adc_pll_inst (
    .inclk0 (adc_clk),
    .c0     (adc_pll_c0),
    .locked (adc_pll_locked)
);


// ADC signals
wire        eoc;            // end of conversion
wire [11:0] dout;           // ADC result
wire        clkout_adccore; // internal ADC clock (not used)

reg         soc;            // start conversion signal


// Hardware ADC block
fiftyfivenm_adcblock adc_hard (
    .clkin_from_pll_c0 (adc_pll_c0),
    .chsel             (5'b00000),
    .soc               (soc),
    .eoc               (eoc),
    .dout              (dout),
    .usr_pwd           (1'b0),
    .tsen              (1'b1),
    .clk_dft           (clkout_adccore)
);


// ADC configuration
defparam adc_hard.device_partname_fivechar_prefix = "10M50";
defparam adc_hard.is_this_first_or_second_adc     = 1;
defparam adc_hard.clkdiv                          = 2;
defparam adc_hard.tsclkdiv                        = 1;
defparam adc_hard.tsclksel                        = 1;
defparam adc_hard.refsel                          = 0;
defparam adc_hard.prescalar                       = 0;
defparam adc_hard.analog_input_pin_mask           = 17'h0;
defparam adc_hard.pwd                             = 0;


// Generate start-of-conversion pulse every ~1 ms
reg [15:0] soc_cnt;

always @(posedge clk or posedge rst) begin

    if (rst) begin
        soc_cnt <= 16'd0;
        soc     <= 1'b0;
    end

    else begin

        soc <= 1'b0;

        if (soc_cnt == 16'd49999) begin
            soc_cnt <= 16'd0;
            soc     <= 1'b1;
        end

        else begin
            soc_cnt <= soc_cnt + 1'b1;
        end

    end

end


// Synchronize EOC signal and capture data
reg eoc_r1, eoc_r2, eoc_r3;

always @(posedge clk or posedge rst) begin

    if (rst) begin

        eoc_r1   <= 1'b0;
        eoc_r2   <= 1'b0;
        eoc_r3   <= 1'b0;

        adc_data <= 12'd0;
        adc_done <= 1'b0;

    end

    else begin

        // sync the signal
        eoc_r1 <= eoc;
        eoc_r2 <= eoc_r1;
        eoc_r3 <= eoc_r2;

        adc_done <= 1'b0;

        // detect rising edge
        if (eoc_r2 & ~eoc_r3) begin

            adc_data <= dout;
            adc_done <= 1'b1;

        end

    end

end

endmodule