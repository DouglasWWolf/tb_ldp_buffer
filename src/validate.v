module validate # (parameter DW = 32, parameter FIFO_DEPTH=2048)
(
    input   clk, resetn,
    input   discard,

    (* X_INTERFACE_MODE = "monitor" *)
    input[DW-1:0] axis_in_tdata,
    input         axis_in_tvalid,


    (* X_INTERFACE_MODE = "monitor" *)
    input[DW-1:0] axis_out_tdata,
    input         axis_out_tvalid,
    input         axis_out_tready,


    output[DW-1:0] axis_dbg_tdata,
    output         axis_dbg_tvalid,

    output         error_stb
);

// Whenever axis_in_tvalid is high, we write an entry to the FIFO
wire[DW-1:0] fifo_in_tdata  = (discard) ? {(DW/16){16'hADDE}} : axis_in_tdata;
wire         fifo_in_tvalid = axis_in_tvalid;

// The output side of the FIFO
wire[DW-1:0] fifo_out_tdata;
wire         fifo_out_tvalid;
wire         fifo_out_tready;

assign fifo_out_tready = (axis_out_tvalid & axis_out_tready);

// Our "debug" stream is just the output side of the FIFO
assign axis_dbg_tdata  = (fifo_out_tvalid) ? fifo_out_tdata : 0;
assign axis_dbg_tvalid = fifo_out_tvalid;

// Signal an error during a handshake on axis_out if the data in the
// FIFO doesn't match the data being presented on axis_out
assign error_stb = (axis_out_tvalid & axis_out_tready) && (fifo_out_tdata != axis_out_tdata);

//=============================================================================
// This holds our buffered frame data.
//=============================================================================
xpm_fifo_axis #
(
   .TDATA_WIDTH     (DW),
   .FIFO_DEPTH      (FIFO_DEPTH),
   .FIFO_MEMORY_TYPE("auto"),
   .PACKET_FIFO     ("false"),
   .USE_ADV_FEATURES("0000"),
   .CLOCKING_MODE   ("common_clock")
)
i_data_fifo
(
    // Clock and reset
   .s_aclk   (clk   ),
   .m_aclk   (clk   ),
   .s_aresetn(resetn),

    // The input bus of the FIFO
   .s_axis_tdata (fifo_in_tdata),
   .s_axis_tvalid(fifo_in_tvalid),
   .s_axis_tready(),

    // The output bus of the FIFO
   .m_axis_tdata (fifo_out_tdata ),
   .m_axis_tvalid(fifo_out_tvalid),
   .m_axis_tready(fifo_out_tready),

    // Unused input stream signals
   .s_axis_tuser(),
   .s_axis_tkeep(),
   .s_axis_tlast(),
   .s_axis_tdest(),
   .s_axis_tid  (),
   .s_axis_tstrb(),

    // Unused output stream signals
   .m_axis_tuser(),
   .m_axis_tdest(),
   .m_axis_tid  (),
   .m_axis_tstrb(),
   .m_axis_tkeep(),
   .m_axis_tlast(),

    // Other unused signals
   .almost_empty_axis(),
   .almost_full_axis(),
   .dbiterr_axis(),
   .prog_empty_axis(),
   .prog_full_axis(),
   .rd_data_count_axis(),
   .sbiterr_axis(),
   .wr_data_count_axis(),
   .injectdbiterr_axis(),
   .injectsbiterr_axis()
);
//=============================================================================


endmodule