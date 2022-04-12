# TODO List

## Transformation

- Identify non-EmuClock clock signals
- Flexible trigger count (currently max. 32)
- Auto-assign address ranges for emulator AXI interfaces
- Variable scan chain width
- Handle "little-endian" wires in Verilog (MSB < LSB)

## RAM Model

- Clean dont-care bits in AXI response for determinism
- Optimize checkpointing of RAM model contents
- WRAP transfer support
- Error signaling check
    - Address out of range (return DECERR)
    - Address cross 4KB boundary (signal a trigger)
    - Unsupported AxSIZE/AxBURST (return SLVERR)
    - Invalid AxLEN for WRAP transfer (return SLVERR)
    - Wrong WLAST position (signal a trigger)
    - Unstable AW/AR/W (signal a trigger)
- Support for DATA_WIDTH > 64
- Random-delay timing model

## Miscellaneous

- Load init data in emulation
