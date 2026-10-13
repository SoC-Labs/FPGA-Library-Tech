// from GLIB_PADLIB.v
//-----------------------------------------------------------------------------
// soclabs generic IO pad model
// Contributors
//
// David Flynn (d.w.flynn@soton.ac.uk)
//
// Copyright 2021-2026 SoC Labs (www.soclabs.org), University of Southampton
// SPDX-License-Identifier: Apache-2.0
//-----------------------------------------------------------------------------

module PAD_INOUT8MA_NOE (
   // Inouts
   PAD, 
   // Outputs
   I, 
   // Inputs
   O,
   NOE
   );
   inout PAD;
   output I;
   input O;
   input NOE;

  IOBUF #(
    .IOSTANDARD ("LVCMOS33"),
    .DRIVE(8)
  ) IOBUF3V3 (
    .O(I),
    .IO(PAD),
    .I(O),
    .T(NOE)
  );
    
endmodule // PAD_INOUT8MA_NOE
