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

module PAD_VSSIO (
   // Inouts
   PAD
   );
   inout PAD;

  IOBUF #(
    .IOSTANDARD ("LVCMOS33"),
    .DRIVE(8)
  ) IOBUF3V3 (
    .O( ),
    .IO(PAD),
    .I(1'b1),
    .T(1'b1)
  );
    
endmodule // PAD_VSSIO
