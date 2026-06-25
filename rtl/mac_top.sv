module mac_top #(
    parameter DATA_WIDTH = 8,
    parameter FIFO_DEPTH_LOG2 = 4
)(
    input  logic                  host_clk,
    input  logic                  host_rst_n,

    input  logic [DATA_WIDTH-1:0] host_tx_tdata,
    input  logic                  host_tx_tvalid,
    input  logic                  host_tx_tlast,
    output logic                  host_tx_tready,

    output logic [DATA_WIDTH-1:0] host_rx_tdata,
    output logic                  host_rx_tvalid,
    output logic                  host_rx_tlast,
    input  logic                  host_rx_tready,
    output logic                  host_rx_error,

    input  logic                  phy_clk,
    input  logic                  phy_rst_n,

    output logic [DATA_WIDTH-1:0] phy_tx_tdata,
    output logic                  phy_tx_tvalid,
    output logic                  phy_tx_tlast,
    input  logic                  phy_tx_tready,

  
    input  logic [DATA_WIDTH-1:0] phy_rx_tdata,
    input  logic                  phy_rx_tvalid,
    input  logic                  phy_rx_tlast,
    output logic                  phy_rx_tready
);

    //INTERNAL CABLES
    logic [DATA_WIDTH:0] tx_fifo_rdata; // 9 bits (TLAST + 8-bit TDATA)
    logic tx_fifo_empty, tx_fifo_full, tx_fifo_rd_en;

    logic [DATA_WIDTH:0] rx_fifo_wdata; // 9 bits (TLAST + 8-bit TDATA)
    logic rx_fifo_empty, rx_fifo_full, rx_fifo_wr_en;


    async_fifo #(
        .DATA_WIDTH(DATA_WIDTH + 1),
        .DEPTH_LOG2(FIFO_DEPTH_LOG2)
    ) tx_fifo (
        .wr_clk(host_clk),
        .wr_rst_n(host_rst_n),
        .wr_en(host_tx_tvalid && !tx_fifo_full),
        .wdata({host_tx_tlast, host_tx_tdata}),
        .full(tx_fifo_full),

        .rd_clk(phy_clk),
        .rd_rst_n(phy_rst_n),
        .rd_en(tx_fifo_rd_en),
        .rdata(tx_fifo_rdata),
        .empty(tx_fifo_empty)
    );

    assign host_tx_tready = !tx_fifo_full; 

    logic mac_tx_ready;
    assign tx_fifo_rd_en = mac_tx_ready && !tx_fifo_empty;

    mac_tx #(
        .DATA_WIDTH(DATA_WIDTH)
    ) tx_core (
        .clk(phy_clk),
        .rst_n(phy_rst_n),

        // Inputs from TX FIFO
        .s_axis_tdata(tx_fifo_rdata[7:0]),
        .s_axis_tvalid(!tx_fifo_empty),
        .s_axis_tlast(tx_fifo_rdata[8]),
        .s_axis_tready(mac_tx_ready),

        // Outputs to Physical Wire
        .m_axis_tdata(phy_tx_tdata),
        .m_axis_tvalid(phy_tx_tvalid),
        .m_axis_tlast(phy_tx_tlast),
        .m_axis_tready(phy_tx_tready)
    );

    logic [DATA_WIDTH-1:0] mac_rx_tdata;
    logic mac_rx_tvalid, mac_rx_tlast, mac_rx_ready;
    logic mac_rx_error_internal;

    mac_rx #(
        .DATA_WIDTH(DATA_WIDTH)
    ) rx_core (
        .clk(phy_clk),
        .rst_n(phy_rst_n),

        // Inputs from Physical Wire
        .s_axis_tdata(phy_rx_tdata),
        .s_axis_tvalid(phy_rx_tvalid),
        .s_axis_tlast(phy_rx_tlast),
        .s_axis_tready(phy_rx_tready),

        // Outputs to RX FIFO
        .m_axis_tdata(mac_rx_tdata),
        .m_axis_tvalid(mac_rx_tvalid),
        .m_axis_tlast(mac_rx_tlast),
        .m_axis_tready(mac_rx_ready),
        .rx_error(mac_rx_error_internal)
    );

    assign mac_rx_ready = !rx_fifo_full;
    assign rx_fifo_wr_en = mac_rx_tvalid && !rx_fifo_full;

    async_fifo #(
        .DATA_WIDTH(DATA_WIDTH + 1),
        .DEPTH_LOG2(FIFO_DEPTH_LOG2)
    ) rx_fifo (
        .wr_clk(phy_clk),
        .wr_rst_n(phy_rst_n),
        .wr_en(rx_fifo_wr_en),
        .wdata({mac_rx_tlast, mac_rx_tdata}),
        .full(rx_fifo_full),

        .rd_clk(host_clk),
        .rd_rst_n(host_rst_n),
        .rd_en(host_rx_tvalid && host_rx_tready), 
        .rdata(rx_fifo_wdata),
        .empty(rx_fifo_empty)
    );

    assign host_rx_tvalid = !rx_fifo_empty;
    assign host_rx_tdata  = rx_fifo_wdata[7:0];
    assign host_rx_tlast  = rx_fifo_wdata[8];
    
    assign host_rx_error = mac_rx_error_internal;

endmodule
