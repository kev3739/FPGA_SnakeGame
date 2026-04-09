# =============================================================================
# snake_de10.sdc  –  Synopsys Design Constraints
# =============================================================================

# ── Primary clock ─────────────────────────────────────────────────────────────
create_clock -name clk50 -period 20.000 [get_ports {MAX10_CLK1_50}]

# ── PLL-generated 25 MHz ──────────────────────────────────────────────────────
derive_pll_clocks

# ── Derive clock uncertainty ──────────────────────────────────────────────────
derive_clock_uncertainty

# ── Input/output delays (relaxed for VGA – timing not critical) ───────────────
set_output_delay -clock clk50 -max 2.0 [get_ports {VGA_*}]
set_output_delay -clock clk50 -min 0.0 [get_ports {VGA_*}]

set_output_delay -clock clk50 -max 2.0 [get_ports {HEX*}]
set_output_delay -clock clk50 -min 0.0 [get_ports {HEX*}]

set_input_delay  -clock clk50 -max 5.0 [get_ports {KEY[*]}]
set_input_delay  -clock clk50 -min 0.0 [get_ports {KEY[*]}]

# ── SPI interface (GSENSOR) – relax for low-speed SPI (~1 MHz) ───────────────
set_false_path -from [get_ports {GSENSOR_SDO}]
set_false_path -to   [get_ports {GSENSOR_CS_N GSENSOR_SCLK GSENSOR_SDI}]
