module axi_stream_register #(
    parameter DATA_WIDTH = 8
)(
    input  logic clk,
    input  logic rst_n,
    input  logic [DATA_WIDTH-1:0] s_axis_tdata,
    input  logic                  s_axis_tvalid,
    output logic                  s_axis_tready,
    output logic [DATA_WIDTH-1:0] m_axis_tdata,
    output logic                  m_axis_tvalid,
    input  logic                  m_axis_tready
);

    assign s_axis_tready = !m_axis_tvalid || m_axis_tready;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            m_axis_tvalid <= 1'b0;
            m_axis_tdata  <= '0;
        end else begin
            if (s_axis_tready) begin
                m_axis_tvalid <= s_axis_tvalid;
                if (s_axis_tvalid) begin
                    m_axis_tdata <= s_axis_tdata;
                end
            end
        end
    end
endmodule
