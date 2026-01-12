`include "timescale.v"

module eth_rxmac_top (
    input        MRxClk,
    input        Reset,
    input        MRxDV,
    input  [7:0] MRxD,          // data from PHY
    input  [47:0] MAC,          // our device MAC
    input  [15:0] MaxFL,        // max frame length
    input        HugEn,         // huge frame enable
    input        r_IFG,         // internal IFG override

    output [7:0] RxDataOut,     // payload to SoC
    output       RxDataValid,
    output       RxError,       // CRC or address error
    output       RxEndFrame
);

    // Internal wires
    wire ByteCntEq0, ByteCntEq1, ByteCntEq2, ByteCntEq3, ByteCntEq4, ByteCntEq5, ByteCntEq6, ByteCntEq7;
    wire ByteCntGreat2, ByteCntSmall7, ByteCntMaxFrame;
    wire [15:0] ByteCntOut;
    wire [3:0]  DlyCrcCnt;
    wire IFGCounterEq24;

    wire StateIdle, StateDrop, StatePreamble, StateSFD;
    wire [1:0] StateData;

    wire RxAbort, AddressMiss;

    wire [31:0] Crc;
    wire CrcError;

    // -------------------------------------------------------------
    // Byte Counters
    eth_rxcounters u_counters (
        .MRxClk(MRxClk),
        .Reset(Reset),
        .MRxDV(MRxDV),
        .StateIdle(StateIdle),
        .StateSFD(StateSFD),
        .StateData(StateData),
        .StateDrop(StateDrop),
        .StatePreamble(StatePreamble),
        .MRxDEqD(MRxD == 8'hD),  // example, depends on SFD detection
        .DlyCrcEn(1'b1),          // enable delayed CRC
        .DlyCrcCnt(DlyCrcCnt),
        .Transmitting(1'b0),
        .MaxFL(MaxFL),
        .r_IFG(r_IFG),
        .HugEn(HugEn),
        .IFGCounterEq24(IFGCounterEq24),
        .ByteCntEq0(ByteCntEq0),
        .ByteCntEq1(ByteCntEq1),
        .ByteCntEq2(ByteCntEq2),
        .ByteCntEq3(ByteCntEq3),
        .ByteCntEq4(ByteCntEq4),
        .ByteCntEq5(ByteCntEq5),
        .ByteCntEq6(ByteCntEq6),
        .ByteCntEq7(ByteCntEq7),
        .ByteCntGreat2(ByteCntGreat2),
        .ByteCntSmall7(ByteCntSmall7),
        .ByteCntMaxFrame(ByteCntMaxFrame),
        .ByteCntOut(ByteCntOut)
    );

    // -------------------------------------------------------------
    // RX State Machine
    eth_rxstatem u_statem (
        .MRxClk(MRxClk),
        .Reset(Reset),
        .MRxDV(MRxDV),
        .ByteCntEq0(ByteCntEq0),
        .ByteCntGreat2(ByteCntGreat2),
        .MRxDEq5(MRxD == 8'h55), // Preamble byte
        .Transmitting(1'b0),
        .MRxDEqD(MRxD == 8'hD),  // SFD byte
        .IFGCounterEq24(IFGCounterEq24),
        .ByteCntMaxFrame(ByteCntMaxFrame),
        .StateData(StateData),
        .StateIdle(StateIdle),
        .StateDrop(StateDrop),
        .StatePreamble(StatePreamble),
        .StateSFD(StateSFD)
    );

    // -------------------------------------------------------------
    // CRC Module
    eth_crc u_crc (
        .Clk(MRxClk),
        .Reset(Reset),
        .Data(MRxD[3:0]),      // feeding 4-bit chunks (or modify for 8-bit)
        .Enable(MRxDV),
        .Initialize(StateSFD),
        .Crc(Crc),
        .CrcError(CrcError)
    );

    // -------------------------------------------------------------
    // Address Checker
    eth_rxaddrcheck u_addrcheck (
        .MRxClk(MRxClk),
        .Reset(Reset),
        .RxData(MRxD),
        .Broadcast(1'b0),
        .r_Bro(1'b0),
        .r_Pro(1'b0),
        .ByteCntEq0(ByteCntEq0),
        .ByteCntEq2(ByteCntEq2),
        .ByteCntEq3(ByteCntEq3),
        .ByteCntEq4(ByteCntEq4),
        .ByteCntEq5(ByteCntEq5),
        .ByteCntEq6(ByteCntEq6),
        .ByteCntEq7(ByteCntEq7),
        .HASH0(32'h0),
        .HASH1(32'h0),
        .CrcHash(6'h0),
        .CrcHashGood(1'b0),
        .StateData(StateData),
        .RxEndFrm(ByteCntMaxFrame),
        .Multicast(1'b0),
        .MAC(MAC),
        .RxAbort(RxAbort),
        .AddressMiss(AddressMiss),
        .PassAll(1'b1),
        .ControlFrmAddressOK(1'b1)
    );


    // ------------------------------------------------------------
    // Header buffer instantiation
    header_buffer #(
        .HEADER_BYTES(192),
        .PTR_W(8)
    ) u_header_buffer (
        .MRxClk        (MRxClk),
        .Reset         (Reset),
        .RxDataValid   (RxDataValid),    // from MAC
        .RxDataOut     (RxDataOut),      // from MAC
        .RxEndFrame    (RxEndFrame),     // from MAC

        .rx_ready      (rx_ready),       // back to MAC
        .header_flat   (header_flat),    // to pipeline / next stage
        .header_len    (header_len),     // packet length
        .header_valid  (header_valid),   // valid signal for downstream
        .header_ready  (header_ready)    // from downstream / pipeline
    );

    // -------------------------------------------------------------
    // Output signals
    assign RxDataOut = MRxD;
    assign RxDataValid = MRxDV & ~StateDrop & ~RxAbort;
    assign RxEndFrame = ByteCntMaxFrame;
    assign RxError = RxAbort | CrcError;

endmodule
