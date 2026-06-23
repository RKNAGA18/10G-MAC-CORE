module async_fifo #(
    parameter DATA_WIDTH = 8,
    parameter DEPTH_LOG2 = 4
)(
    input  logic                  wr_clk,
    input  logic                  wr_rst_n,
    input  logic                  wr_en,
    input  logic [DATA_WIDTH-1:0] wdata,
    output logic                  full,

    input  logic                  rd_clk,
    input  logic                  rd_rst_n,
    input  logic                  rd_en,
    output logic [DATA_WIDTH-1:0] rdata,
    output logic                  empty
);

    localparam DEPTH = 1 << DEPTH_LOG2;
    logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    logic [DEPTH_LOG2:0] wr_ptr_bin, wr_ptr_gray, wr_ptr_gray_next, wr_ptr_bin_next;
    logic [DEPTH_LOG2:0] rd_ptr_bin, rd_ptr_gray, rd_ptr_gray_next, rd_ptr_bin_next;

    logic [DEPTH_LOG2:0] wr_ptr_gray_sync1, wr_ptr_gray_sync2;
    logic [DEPTH_LOG2:0] rd_ptr_gray_sync1, rd_ptr_gray_sync2;
    
    logic full_val, empty_val;

    assign wr_ptr_bin_next  = wr_ptr_bin + (wr_en & ~full);
    assign wr_ptr_gray_next = (wr_ptr_bin_next >> 1) ^ wr_ptr_bin_next;
    assign full_val = (wr_ptr_gray_next == {~rd_ptr_gray_sync2[DEPTH_LOG2:DEPTH_LOG2-1], rd_ptr_gray_sync2[DEPTH_LOG2-2:0]});

    always_ff @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n) begin
            wr_ptr_bin  <= '0;
            wr_ptr_gray <= '0;
            full        <= 1'b0;
        end else begin
            if (wr_en && !full) mem[wr_ptr_bin[DEPTH_LOG2-1:0]] <= wdata;
            wr_ptr_bin  <= wr_ptr_bin_next;
            wr_ptr_gray <= wr_ptr_gray_next;
            full        <= full_val;
        end
    end

    always_ff @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n) begin
            rd_ptr_gray_sync1 <= '0;
            rd_ptr_gray_sync2 <= '0;
        end else begin
            rd_ptr_gray_sync1 <= rd_ptr_gray;
            rd_ptr_gray_sync2 <= rd_ptr_gray_sync1;
        end
    end

    assign rd_ptr_bin_next  = rd_ptr_bin + (rd_en & ~empty);
    assign rd_ptr_gray_next = (rd_ptr_bin_next >> 1) ^ rd_ptr_bin_next;
    assign empty_val = (rd_ptr_gray_next == wr_ptr_gray_sync2);

    assign rdata = mem[rd_ptr_bin[DEPTH_LOG2-1:0]];

    always_ff @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) begin
            rd_ptr_bin  <= '0;
            rd_ptr_gray <= '0;
            empty       <= 1'b1; 
        end else begin
            rd_ptr_bin  <= rd_ptr_bin_next;
            rd_ptr_gray <= rd_ptr_gray_next;
            empty       <= empty_val;
        end
    end

    always_ff @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) begin
            wr_ptr_gray_sync1 <= '0;
            wr_ptr_gray_sync2 <= '0;
        end else begin
            wr_ptr_gray_sync1 <= wr_ptr_gray;
            wr_ptr_gray_sync2 <= wr_ptr_gray_sync1;
        end
    end
endmodule
