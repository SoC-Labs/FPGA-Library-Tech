//-----------------------------------------------------------------------------
// Copied from nanosoc_m0_soc src/rtl/fpga_lib/rom/sl_fpga_rom_word.v (itself
// vendored unmodified from ethernet-subsystem-ahb src/rtl/fpga_lib/), where only
// the legacy pynq/ flow could reach it. Its logic is unchanged; this header,
// the image-format note and the `ifdef RAM_PRELOAD_WORD guard are new.
//
// WHY THE WHOLE MODULE IS GUARDED. This file is listed in
// flist/fpga_lib_mem_ip.flist, which every simulation of the SoC also reads.
// A module that is compiled and not instantiated becomes an extra TOP in VCS:
// the default simulation would grow from 120 to 121 modules, and its initial
// block would try to $readmemh a file that does not exist. Guarded, the file
// contributes nothing unless sl_ahb_rom.v is also selecting it, so every build
// that does not define RAM_PRELOAD_WORD compiles exactly what it did before.
//-----------------------------------------------------------------------------
// SoCLabs Vivado-friendly FPGA preloaded BRAM (word-format $readmemh).
//
// Despite the "rom" in the filename this is actually a writable BRAM whose
// initial content is supplied by a word-format $readmemh hex file — i.e.
// a "preload" SRAM, not a true ROM. Keeping the file name avoids churn
// in the rest of the IP filelists; the module was previously strictly-
// read-only, which made SWD-driven firmware hot-flash impossible:
//   - The write port (WDATA / WREN) was tied off internally.
//   - `mww` from OpenOCD appeared to succeed on readback but left the
//     BRAM content unchanged (cmsdk_ahb_to_sram drove WEN correctly,
//     but the BRAM ignored it).
//   - Every SYSRESETREQ reverted IMEM to the baked image, and
//     firmware iteration required a full Vivado rebuild.
//
// Writable preload fixes all three: the $readmemh initial content
// provides a bootable firmware out of the bitstream, and debugger
// writes persist (BRAM cells on 7-series are NOT reset-clearable),
// so an SWD-loaded image survives a SYSRESETREQ and is picked up on
// the next Reset_Handler.
//
// Replaces the ARM cmsdk_fpga_rom — its byte-shuffle for-loop in an
// initial block triggered Vivado's "ignoring non-constant assignment
// in initial block" warning and left BRAM contents zero. This module
// reads a single 32-bit-word-format hex file directly into a 32-bit-
// wide BRAM array (one $readmemh, no loop, no temp).
//
// The image must be WORD format: one 32-bit word per line, as a byte-format
// hex from `arm-none-eabi-objcopy -O verilog` becomes after conversion (the
// FPGA consumers carry a hex_byte_to_word.py for this). A byte-format hex
// read by this module loads one byte per word and the CPU runs garbage.
//
// Pin-compatible with the cmsdk_fpga_rom / cmsdk_fpga_sram interface
// used by sl_ahb_rom.v and sl_ahb_sram.v.
//
// Copyright 2021-2026 SoC Labs (www.soclabs.org), University of Southampton
// SPDX-License-Identifier: Apache-2.0
//-----------------------------------------------------------------------------

`ifdef RAM_PRELOAD_WORD

module sl_fpga_rom_word #(
    parameter AW       = 16,          // address bits (byte-addressed range)
    parameter filename = "image_word.hex"
)(
    input  wire          CLK,
    input  wire [AW-1:2] ADDR,
    input  wire [31:0]   WDATA,        // AHB write data (byte-strobed via WREN)
    input  wire [3:0]    WREN,         // per-byte write enables
    input  wire          CS,
    output wire [31:0]   RDATA
);

    localparam DEPTH = 1 << (AW - 2);

    // Single-port inferred BRAM with $readmemh preload + per-byte writes.
    // ram_style=block forces BRAM mapping (was previously pinned with
    // rom_style="block" too; rom_style is dropped because we now have
    // a live write port). 7-series BRAM cells retain state across
    // HRESETn, so SWD-written firmware survives a SYSRESETREQ.
    (* ram_style = "block" *)
    reg [31:0] mem [0:DEPTH-1];

    // Zero-init before $readmemh: the hex file only covers the populated
    // firmware range, and any unfilled address comes up X in sim. X
    // values leak through cmsdk_ahb_to_sram (read data mux) onto HRDATA
    // and propagate into the core on a prefetch past the image, causing
    // intermittent sim flake depending on compile ordering. Explicit
    // zero-fill is also what `ARM_ASSERT_ON` does in cmsdk_fpga_rom —
    // we can't enable that globally because the Cortex-M0 core pulls
    // unresolved OVL checkers under the same define.
    initial begin : mem_init
        integer i;
        for (i = 0; i < DEPTH; i = i + 1) begin
            mem[i] = 32'h0;
        end
        $readmemh(filename, mem);
    end

    reg [31:0] rdata_r;

    always @(posedge CLK) begin
        if (CS) begin
            // Byte-enable-aware write. Vivado infers a byte-write-enabled
            // BRAM when the per-lane structure is this explicit, which
            // also preserves the $readmemh initial content.
            if (WREN[0]) mem[ADDR][ 7: 0] <= WDATA[ 7: 0];
            if (WREN[1]) mem[ADDR][15: 8] <= WDATA[15: 8];
            if (WREN[2]) mem[ADDR][23:16] <= WDATA[23:16];
            if (WREN[3]) mem[ADDR][31:24] <= WDATA[31:24];
            rdata_r <= mem[ADDR];
        end else begin
            rdata_r <= 32'h0;
        end
    end

    assign RDATA = rdata_r;

endmodule

`endif // RAM_PRELOAD_WORD
