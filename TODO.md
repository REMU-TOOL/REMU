# TODO List

## Transformation

- Support user-generated clock signals
- Auto-assign address ranges for emulator AXI interfaces

## RAM Model

- Data must be held until target clock fires in output channel (host -> target)
- Clean dont-care bits in AXI response for determinism
- Optimize checkpointing of RAM model contents
- AXI signaling check
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
- 4KB boundary check in simple DMA
