module mac_rx #(
    parameter DATA_WIDTH = 8
)(
    input  logic clk,
    input  logic rst_n,

    // SLAVE INTERFACE (From Wire)
    input  logic [DATA_WIDTH-1:0] s_axis_tdata,
    input  logic                  s_axis_tvalid,
    input  logic                  s_axis_tlast,
    output logic                  s_axis_tready,

    // MASTER INTERFACE (To Host)
    output logic [DATA_WIDTH-1:0] m_axis_tdata,
    output logic                  m_axis_tvalid,
    output logic                  m_axis_tlast,
    input  logic                  m_axis_tready,
    
    output logic                  rx_error
);

    typedef enum logic [1:0] {
        HUNT     = 2'd0,
        PREAMBLE = 2'd1,
        DATA     = 2'd2
    } state_t;

    state_t current_state, next_state;

    // 4-Byte Lookahead Delay Pipeline Registers
    logic [7:0] d_pipe [0:3];
    logic [3:0] v_pipe;
    
    logic [31:0] crc_reg, next_crc;

    crc32_d8 crc_engine (
        .data(d_pipe[3]),
        .crc_in(crc_reg),
        .crc_out(next_crc)
    );

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= HUNT;
            crc_reg       <= 32'hFFFFFFFF;
            rx_error      <= 1'b0;
            v_pipe        <= 4'b0000;
            // THE FIX: Added the 'h' for hexadecimal base
            d_pipe[0] <= 8'h00; d_pipe[1] <= 8'h00; d_pipe[2] <= 8'h00; d_pipe[3] <= 8'h00;
        end else begin
            current_state <= next_state;

            if (current_state == HUNT) begin
                crc_reg <= 32'hFFFFFFFF;
                v_pipe  <= 4'b0000;
            end 
            
            if (current_state == HUNT && s_axis_tvalid && s_axis_tdata == 8'h55) begin
                rx_error <= 1'b0;
            end

            if (current_state == DATA && s_axis_tvalid && m_axis_tready) begin
                d_pipe[0] <= s_axis_tdata;
                d_pipe[1] <= d_pipe[0];
                d_pipe[2] <= d_pipe[1];
                d_pipe[3] <= d_pipe[2];
                v_pipe    <= {v_pipe[2:0], 1'b1};

                if (v_pipe[3]) begin
                    crc_reg <= next_crc;
                end

                if (s_axis_tlast) begin
                    if ({d_pipe[2], d_pipe[1], d_pipe[0], s_axis_tdata} != ~next_crc) begin
                        rx_error <= 1'b1;
                    end
                end
            end
        end
    end

    always_comb begin
        next_state = current_state; 
        case (current_state)
            HUNT:     if (s_axis_tvalid && s_axis_tdata == 8'h55) next_state = PREAMBLE;
            PREAMBLE: if (s_axis_tvalid && s_axis_tdata == 8'hD5) next_state = DATA;
                      else if (s_axis_tvalid && s_axis_tdata != 8'h55) next_state = HUNT;
            DATA:     if (s_axis_tvalid && s_axis_tlast && m_axis_tready) next_state = HUNT;
            default:  next_state = HUNT;
        endcase
    end

    always_comb begin
        m_axis_tvalid = (current_state == DATA) ? (s_axis_tvalid && v_pipe[3]) : 1'b0;
        m_axis_tdata  = d_pipe[3];
        m_axis_tlast  = (current_state == DATA) ? (s_axis_tvalid && s_axis_tlast) : 1'b0;
        s_axis_tready = m_axis_tready; 
    end

endmodule
