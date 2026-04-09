# FPGA Snake Game — DE10-Lite

A hardware Snake game implemented in Verilog and targeting the Intel DE10-Lite board (MAX 10 FPGA). The snake is controlled by tilting the board using the onboard ADXL345 accelerometer, and the game speed changes based on the chip's die temperature read from the internal ADC.

---

## Features

- Tilt-to-direction control via ADXL345 accelerometer over SPI
- Dynamic game speed based on chip temperature (hotter = faster snake)
- 640×480 VGA output at ~60 Hz
- Score displayed on HEX0 and HEX1 (7-segment displays)
- Wall and self-collision detection
- Game over screen (solid red) with reset via KEY[0]
- Pseudo-random food placement using a 16-bit Galois LFSR

---

## Hardware Requirements

| Component | Details |
|---|---|
| FPGA Board | Terasic DE10-Lite |
| Device | Intel MAX 10 — 10M50DAF484C6GES |
| Display | VGA monitor (640×480 @ 60 Hz) |
| Accelerometer | ADXL345 (onboard) |
| Tools | Quartus Prime Lite 25.1 |

---

## Project Structure

```
├── snake_top.v           # Top-level module — wires everything together
├── game_engine.v         # Snake game logic and pixel renderer
├── snake_body.v          # Body segment shift register
├── vga_sync.v            # VGA timing generator (640×480 @ 60 Hz)
├── accel_spi.v           # ADXL345 SPI driver
├── accel_dir_decoder.v   # Tilt to direction converter
├── adc_controller.v      # MAX 10 internal temperature ADC
├── adc_pll.v             # 1:1 PLL pass-through for ADC clock input
├── adc_speed_ctrl.v      # Maps temperature reading to game speed
├── clk_div.v             # Variable clock divider
├── pll_25m.v             # 50 MHz to 25 MHz clock divider
├── lfsr_food.v           # Pseudo-random food position generator
├── seg7_decoder.v        # BCD to 7-segment decoder
├── snake_game.qpf        # Quartus project file
└── snake_game.qsf        # Quartus settings and pin assignments
```

---

## How It Works

### Controls
Tilt the DE10-Lite board in the direction you want the snake to move. The accelerometer detects which axis is tilted more and outputs one of four directions. The snake cannot reverse 180° into itself.

### Game Speed
The onboard MAX 10 ADC reads the chip die temperature approximately every 1 ms. A higher temperature maps to a smaller tick divisor, making the snake move faster. At room temperature the snake runs at roughly 2–3 steps per second.

### Scoring
Each piece of food eaten increments the score by 1. The ones digit is shown on HEX0 and the tens digit on HEX1. The internal counter continues past 99 but the display wraps.

### Reset
Press **KEY[0]** at any time to reset the game and restart from the beginning.

---

## Building and Programming

1. Open `snake_game.qpf` in Quartus Prime Lite
2. Run **Processing → Start Compilation** (or Ctrl+L)
3. Connect the DE10-Lite via USB-Blaster
4. Open the Programmer and load `output_files/snake_game.sof`

---

## Clocks

| Clock | Source | Used By |
|---|---|---|
| 50 MHz | MAX10_CLK1_50 | SPI, accelerometer decoder, ADC |
| 25 MHz | pll_25m (toggle FF) | VGA sync, game engine |
| 10 MHz | ADC_CLK_10 | adc_pll → ADC hard block |

---

## Known Limitations

- Maximum snake length is 32 segments
- Score display rolls over after 99
- Food can theoretically spawn on a body segment (rare with LFSR)
