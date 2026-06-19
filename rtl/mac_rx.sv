module mac_rx #(
    parameter DATA_WIDTH = 8
)(
    input  logic clk,
    input  logic rst_n,

    // SLAVE INTERFACE (From Network PHY - The Wire)
    input  logic [DATA_WIDTH-1:0] s_axis_tdata,
    input  logic                  s_axis_tvalid,
    input  logic                  s_axis_tlast,
    output logic                  s_axis_tready,

    // MASTER INTERFACE (To Host CPU/NPU)
    output logic [DATA_WIDTH-1:0] m_axis_tdata,
    output logic                  m_axis_tvalid,
    output logic                  m_axis_tlast,
    input  logic                  m_axis_tready
);

    typedef enum logic [2:0] {
        HUNT      = 3'd0,
        PREAMBLE  = 3'd1,
        DATA      = 3'd2,
        CHECK_FCS = 3'd3
    } state_t;

    state_t current_state, next_state;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) current_state <= HUNT;
        else        current_state <= next_state;
    end

    always_comb begin
        next_state = current_state; 
        case (current_state)
            HUNT: begin
                if (s_axis_tvalid && s_axis_tdata == 8'h55) next_state = PREAMBLE;
            end
            PREAMBLE: begin
                if (s_axis_tvalid) begin
                    if (s_axis_tdata == 8'hD5) next_state = DATA;
                    else if (s_axis_tdata != 8'h55) next_state = HUNT; // False alarm!
                end
            end
            DATA: begin
                if (s_axis_tvalid && s_axis_tlast) next_state = CHECK_FCS;
            end
            CHECK_FCS: next_state = HUNT;
            default: next_state = HUNT;
        endcase
    end

    always_comb begin
        m_axis_tvalid = 1'b0;
        m_axis_tdata  = 8'h00;
        m_axis_tlast  = 1'b0;
        s_axis_tready = 1'b1; 

        case (current_state)
            DATA: begin
                m_axis_tvalid = s_axis_tvalid;
                m_axis_tdata  = s_axis_tdata;
                s_axis_tready = m_axis_tready; 
            end
        endcase
    end
endmodule
