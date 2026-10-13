//-----------------------------------------------------------------------------
// SoCLabs FPGA SRAM Wrapper 
// - to be substitued with same name file in filelist when moving to ASIC
// Contributors
//
// David Mapstone (d.a.mapstone@soton.ac.uk)
//
// Copyright 2021-2026 SoC Labs (www.soclabs.org), University of Southampton
// SPDX-License-Identifier: Apache-2.0
//-----------------------------------------------------------------------------

module sl_ahb_sram #(
    // System Parameters
    parameter SYS_DATA_W = 32,  // System Data Width
    parameter RAM_ADDR_W = 14,  // Size of SRAM
    parameter RAM_DATA_W = 32   // Data Width of RAM
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

    // FPGA SRAM model
    cmsdk_fpga_sram #(
        .AW (RAM_ADDR_W)
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
endmodule