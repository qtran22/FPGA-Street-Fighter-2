# FPGA Street Fighter 2

A hardware-software co-design recreation of Street Fighter 2 built on the Urbana Xilinx 7 FPGA. The game renders to a display via VGA-to-HDMI output, with game logic split between SystemVerilog hardware modules and embedded C software running on the on-chip processor in Vitis.

---

## Features

- **Two playable characters** — Ken and Ryu, each with punch and kick attacks
- **Real-time combat** — Hit detection and attack logic handled in hardware via FSMs
- **Health bar system** — Player health tracked and updated in embedded C (Vitis)
- **Sprite rendering** — Character sprites and animations rendered over VGA/HDMI output
- **Two-player input** — Custom controller input handling for both players simultaneously
- **Game state management** — FSM-driven game states (idle, fighting, round end)

---

## Hardware & Software Requirements

### Hardware
- Urbana Xilinx 7 FPGA board
- HDMI Cable + HDMI display
- One Keyboard

### Software
- **Vivado** — HDL synthesis, implementation, and bitstream generation
- **Vitis** — Embedded C development and deployment to on-chip processor
- **SystemVerilog** — Hardware description language used for all HDL modules

---

## Project Structure

```
fpga-street-fighter-2/
├── hardware/
│   ├── top.sv                  # Top-level module
│   ├── fsm_game.sv             # Game state FSM
│   ├── fsm_player.sv           # Player movement & attack FSM
│   ├── hit_detection.sv        # Hit detection logic
│   ├── vga_controller.sv       # VGA timing and sync
│   ├── sprite_renderer.sv      # Sprite and animation rendering
│   └── controller_input.sv     # Controller input handling
├── software/
│   └── main.c                  # Embedded C: health bar logic, game loop
├── sprites/
│   └── *.coe                   # Sprite ROM data for Ken and Ryu
└── constraints/
    └── constraints.xdc         # Pin assignments and timing constraints
```

---

## How to Build & Run

### 1. Clone the repository

```bash
git clone https://github.com/yourusername/fpga-street-fighter-2.git
cd fpga-street-fighter-2
```

### 2. Open in Vivado

1. Launch **Vivado** and open the project from the `hardware/` directory
2. Run **Synthesis** → **Implementation** → **Generate Bitstream**
3. Connect your Urbana board via USB and program it:
   - Go to **Open Hardware Manager** → **Program Device**
   - Select the generated `.bit` file

### 3. Deploy the software in Vitis

1. Open **Vitis** and create a new application project targeting the Urbana board
2. Import `software/main.c` into the project
3. Build the project and **Run** to deploy the embedded C application to the on-chip processor

### 4. Connect peripherals & play

1. Plug in both controllers
2. Connect the VGA-to-HDMI adapter to your display
3. Power on the board — the game should load to the start screen
4. **Player 1** controls Ken, **Player 2** controls Ryu

---

## Gameplay Controls

| Action      | Player 1 | Player 2 |
|-------------|----------|----------|
| Move Left   | ←        | ←        |
| Move Right  | →        | →        |
| Punch       | Button A | Button A |
| Kick        | Button B | Button B |

---

## Architecture Overview

The project uses a hardware-software co-design approach:

- **SystemVerilog (Vivado)** handles all timing-critical logic — sprite rendering, VGA sync, FSM-driven player movement, attack animations, and hit detection
- **Embedded C (Vitis)** runs on the soft processor and manages game state data including health points, damage calculation, and round outcomes
- Communication between hardware and software is done via **memory-mapped I/O**
