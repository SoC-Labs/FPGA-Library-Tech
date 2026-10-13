# FPGA Library Tech

FPGA technology library for SoC Labs designs: behavioural SRAM and ROM
wrappers with an AHB-Lite slave interface, and pad stubs, so that an SoC can
be simulated and built for FPGA without a foundry memory compiler or pad
library. For an ASIC build, a technology library with the same module names
replaces these files through the filelist.

- `sram/verilog/sl_ahb_sram.v`: AHB-Lite SRAM wrapper.
- `rom/verilog/sl_ahb_rom.v`, `rom/verilog/sl_fpga_rom_word.v`: AHB-Lite ROM
  wrapper; an FPGA build can preload IMEM (`RAM_PRELOAD_WORD`).
- `pads/verilog/`: pad stubs.
- `flist/fpga_lib_mem_ip.flist`: filelist; set `SOCLABS_FPGA_LIB_TECH_DIR`.

Used as a submodule by the nanoSoC M0 QuickStart SoC
(https://github.com/SoC-Labs/nanoSoC-QuickStart-M0).

Licence: Apache-2.0 (see LICENSE and NOTICE).
