//-----------------------------------------------------------------------------
// SoCLabs FPGA ROM Wrapper 
// - to be substitued with same name file in filelist when moving to ASIC
// Contributors
//
// David Mapstone (d.a.mapstone@soton.ac.uk)
//
// Copyright 2021-2026 SoC Labs (www.soclabs.org), University of Southampton
// SPDX-License-Identifier: Apache-2.0
//-----------------------------------------------------------------------------

module sl_ahb_rom #(
    // System Parameters
    parameter SYS_DATA_W = 32,  // System Data Width
    parameter RAM_ADDR_W = 14,  // Size of SRAM
    parameter RAM_DATA_W = 32,  // Data Width of RAM
    parameter FILENAME   = "image.hex" // Initial Image to Populate Memory with
)(
    // --------------------------------------------------------------------------
    // Port Definitions
    // --------------------------------------------------------------------------
    input  wire                  HCLK,      // clock
    input  wire                  HRESETn,   // active-low reset
    input  wire                  HSEL,      // slave select from the decoder
    input  wire                  HREADY,    // bus ready (previous transfer done)
    input  wire            [1:0] HTRANS,    // transfer kind (IDLE/BUSY/NONSEQ/SEQ)
    input  wire            [2:0] HSIZE,     // access width
    input  wire                  HWRITE,    // 1 = write, 0 = read
    input  wire [RAM_ADDR_W-1:0] HADDR,     // byte address within this memory
    input  wire [SYS_DATA_W-1:0] HWDATA,    // data to write
    output wire                  HREADYOUT, // this slave is ready
    output wire                  HRESP,     // transfer response
    output wire [SYS_DATA_W-1:0] HRDATA     // data read
);
    
    // Internal Wiring
    wire  [RAM_ADDR_W-3:0] addr;
    wire  [RAM_DATA_W-1:0] wdata;
    wire  [RAM_DATA_W-1:0] rdata;
    wire             [3:0] wen;
    wire                   cs;
    
    // AHB to SRAM Conversion
    cmsdk_ahb_to_sram #(
        .AW (RAM_ADDR_W)
    ) u_ahb_to_sram (
        // AHB Inputs
        .HCLK       (HCLK),
        .HRESETn    (HRESETn),
        .HSEL       (HSEL),  
        .HADDR      (HADDR[RAM_ADDR_W-1:0]),
        .HTRANS     (HTRANS),
        .HSIZE      (HSIZE),
        .HWRITE     (HWRITE),
        .HWDATA     (HWDATA),
        .HREADY     (HREADY),

        // AHB Outputs
        .HREADYOUT  (HREADYOUT),
        .HRDATA     (HRDATA),
        .HRESP      (HRESP),

        // SRAM input
        .SRAMRDATA  (rdata),
        
        // SRAM Outputs
        .SRAMADDR   (addr),
        .SRAMWDATA  (wdata),
        .SRAMWEN    (wen),
        .SRAMCS     (cs)
   );

    // Memory model selection.
    //
    // RAM_PRELOAD_WORD defined: sl_fpga_rom_word, one $readmemh of a WORD-format
    //   hex (one 32-bit word per line) straight into a 32-bit BRAM array. This is
    //   the branch an FPGA build needs: Vivado synthesises it and the BRAM comes
    //   up holding the image.
    // Otherwise: cmsdk_fpga_rom, exactly as before. It reads a BYTE-format hex
    //   into a byte array and copies it into four byte lanes in an initial-block
    //   loop. That works in RTL simulation, and Vivado drops the loop (Synth
    //   8-311), so on an FPGA this branch comes up ZERO and nothing fails.
    //
    // WHY NOT `ifdef RAM_PRELOAD, the define the legacy pynq/ copy of this file
    // uses. Here RAM_PRELOAD means only "IMEM is this preloadable ROM"
    // (nanosoc_region_imem.v), and the simulation flow defines it too
    // (nanosoc_arch_tech flows/makefile.simulate), handing this module the
    // byte-format image.hex that objcopy writes. Keyed on RAM_PRELOAD, every
    // simulation would switch to the word loader, read one byte per word and
    // fail. The FPGA flow therefore asks for the word loader by name, alongside
    // RAM_PRELOAD. Nothing defined RAM_PRELOAD_WORD before this file did, so
    // every existing simulation and FPGA build compiles what it compiled before.
`ifdef RAM_PRELOAD_WORD
    sl_fpga_rom_word #(
        .AW (RAM_ADDR_W),
        .filename (FILENAME)
    ) u_sram (
        .CLK        (HCLK),
        .ADDR       (addr),
        .WDATA      (wdata),
        .WREN       (wen),
        .CS         (cs),
        .RDATA      (rdata)
    );
`else
    // FPGA SRAM model
    cmsdk_fpga_rom #(
        .AW (RAM_ADDR_W),
        .filename (FILENAME)
    ) u_sram (
        // SRAM Inputs
        .CLK        (HCLK),
        .ADDR       (addr),
        .WDATA      (wdata),
        .WREN       (wen),
        .CS         (cs),
        
        // SRAM Output
        .RDATA      (rdata)
    );
`endif
endmodule