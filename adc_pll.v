// =============================================================================
// adc_pll.v  --  PLL for ADC Clock
//
// This module passes the 10 MHz ADC clock through a PLL.
// The ADC hardware requires its clock to come from a PLL output,
// so we use a 1:1 PLL (same input and output frequency).
//
// Input:  10 MHz
// Output: 10 MHz
// =============================================================================

module adc_pll (
    input  wire inclk0,   // 10 MHz input clock
    output wire c0,       // 10 MHz output clock
    output wire locked    // goes high when PLL is ready
);

wire [4:0] sub_wire0;   // PLL clock outputs
wire       sub_wire1;   // PLL lock signal

assign c0     = sub_wire0[0];
assign locked = sub_wire1;


// PLL block
altpll altpll_component (
    .inclk          ({1'b0, inclk0}),
    .clk            (sub_wire0),
    .locked         (sub_wire1),

    // unused control signals
    .areset         (1'b0),
    .clkena         ({6{1'b1}}),
    .clkswitch      (1'b0),
    .configupdate   (1'b0),
    .pfdena         (1'b1),
    .phasecounterselect ({4{1'b1}}),
    .phasestep      (1'b1),
    .phaseupdown    (1'b1),
    .pllena         (1'b1),
    .scanaclr       (1'b0),
    .scanclk        (1'b0),
    .scanclkena     (1'b1),
    .scandata       (1'b0),

    // unused outputs
    .activeclock    (),
    .clkbad         (),
    .clkloss        (),
    .enable0        (),
    .enable1        (),
    .extclk         (),
    .fbmimicbidir   (),
    .fbout          (),
    .fref           (),
    .icdrclk        (),
    .phasedone      (),
    .scandataout    (),
    .scandone       (),
    .sclkout0       (),
    .sclkout1       (),
    .vcooverrange   (),
    .vcounderrange  ()
);


// PLL settings
defparam
    altpll_component.bandwidth_type          = "AUTO",
    altpll_component.clk0_divide_by          = 1,
    altpll_component.clk0_duty_cycle         = 50,
    altpll_component.clk0_multiply_by        = 1,
    altpll_component.clk0_phase_shift        = "0",
    altpll_component.compensate_clock        = "CLK0",
    altpll_component.inclk0_input_frequency  = 100000,
    altpll_component.intended_device_family  = "MAX 10",
    altpll_component.lpm_type                = "altpll",
    altpll_component.operation_mode          = "NORMAL",
    altpll_component.pll_type                = "AUTO",

    altpll_component.port_activeclock        = "PORT_UNUSED",
    altpll_component.port_areset             = "PORT_UNUSED",
    altpll_component.port_clkbad0            = "PORT_UNUSED",
    altpll_component.port_clkbad1            = "PORT_UNUSED",
    altpll_component.port_clkloss            = "PORT_UNUSED",
    altpll_component.port_clkswitch          = "PORT_UNUSED",
    altpll_component.port_configupdate       = "PORT_UNUSED",
    altpll_component.port_fbin               = "PORT_UNUSED",
    altpll_component.port_fbout              = "PORT_UNUSED",
    altpll_component.port_fref               = "PORT_UNUSED",
    altpll_component.port_icdrclk            = "PORT_UNUSED",

    altpll_component.port_inclk0             = "PORT_USED",
    altpll_component.port_inclk1             = "PORT_UNUSED",
    altpll_component.port_locked             = "PORT_USED",

    altpll_component.port_pfdena             = "PORT_UNUSED",
    altpll_component.port_phasecounterselect = "PORT_UNUSED",
    altpll_component.port_phasedone          = "PORT_UNUSED",
    altpll_component.port_phasestep          = "PORT_UNUSED",
    altpll_component.port_phaseupdown        = "PORT_UNUSED",
    altpll_component.port_pllena             = "PORT_UNUSED",

    altpll_component.port_scanaclr           = "PORT_UNUSED",
    altpll_component.port_scanclk            = "PORT_UNUSED",
    altpll_component.port_scanclkena         = "PORT_UNUSED",
    altpll_component.port_scandata           = "PORT_UNUSED",
    altpll_component.port_scandataout        = "PORT_UNUSED",
    altpll_component.port_scandone           = "PORT_UNUSED",
    altpll_component.port_scanread           = "PORT_UNUSED",
    altpll_component.port_scanwrite          = "PORT_UNUSED",

    altpll_component.port_clk0               = "PORT_USED",
    altpll_component.port_clk1               = "PORT_UNUSED",
    altpll_component.port_clk2               = "PORT_UNUSED",
    altpll_component.port_clk3               = "PORT_UNUSED",
    altpll_component.port_clk4               = "PORT_UNUSED",
    altpll_component.port_clk5               = "PORT_UNUSED",

    altpll_component.port_extclk0            = "PORT_UNUSED",
    altpll_component.port_extclk1            = "PORT_UNUSED",
    altpll_component.port_extclk2            = "PORT_UNUSED",
    altpll_component.port_extclk3            = "PORT_UNUSED",

    altpll_component.self_reset_on_loss_lock = "OFF",
    altpll_component.width_clock             = 5;

endmodule