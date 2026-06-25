module mac_tx #(
    parameter DATA_WIDTH = 8
)(
    input  logic clk,
    input  logic rst_n,

    input  logic [DATA_WIDTH-1:0] s_axis_tdata,
    input  logic                  s_axis_tvalid,
    input  logic                  s_axis_tlast,
    output logic                  s_axis_tready,

    output logic [DATA_WIDTH-1:0] m_axis_tdata,
    output logic                  m_axis_tvalid,
    output logic                  m_axis_tlast,
    input  logic                  m_axis_tready
);

    typedef enum logic [2:0] {
        IDLE      = 3'd0,
        PREAMBLE  = 3'd1,
        DATA      = 3'd2,
        FCS       = 3'd3
    } state_t;

    state_t current_state, next_state;
    logic [3:0] byte_counter;
    logic [31:0] crc_reg, next_crc;

    crc32_d8 crc_engine (
        .data(s_axis_tdata),
        .crc_in(crc_reg),
        .crc_out(next_crc)
    );

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= IDLE;
            byte_counter  <= '0;
            crc_reg       <= 32'hFFFFFFFF;
        end else begin
            current_state <= next_state;
            
            if (current_state == PREAMBLE || current_state == FCS) begin
                byte_counter <= byte_counter + 1;
            end else begin
                byte_counter <= '0;
            end

            if (current_state == IDLE) begin
                crc_reg <= 32'hFFFFFFFF;
            end else if (current_state == DATA && s_axis_tvalid && m_axis_tready) begin
                crc_reg <= next_crc;
            end
        end
    end

    always_comb begin
        next_state = current_state;
        case (current_state)
            IDLE:     if (s_axis_tvalid) next_state = PREAMBLE;
            PREAMBLE: if (byte_counter == 4'd7) next_state = DATA;
            DATA:     if (s_axis_tvalid && s_axis_tlast && m_axis_tready) next_state = FCS;
            FCS:      if (byte_counter == 4'd3 && m_axis_tready) next_state = IDLE;
            default:  next_state = IDLE;
        endcase
    end

    // THE FIX: Icarus Bug Bypass
    // Extract constant slices outside the always_comb block
    logic [7:0] fcs_byte_0, fcs_byte_1, fcs_byte_2, fcs_byte_3;
    assign fcs_byte_0 = ~crc_reg[31:24];
    assign fcs_byte_1 = ~crc_reg[23:16];
    assign fcs_byte_2 = ~crc_reg[15:8];
    assign fcs_byte_3 = ~crc_reg[7:0];

    always_comb begin
        m_axis_tdata  = 8'h00;
        m_axis_tvalid = 1'b0;
        m_axis_tlast  = 1'b0;
        s_axis_tready = 1'b0;

        case (current_state)
            PREAMBLE: begin
                m_axis_tvalid = 1'b1;
                m_axis_tdata  = (byte_counter == 4'd7) ? 8'hD5 : 8'h55;
            end
            DATA: begin
                m_axis_tvalid = s_axis_tvalid;
                m_axis_tdata  = s_axis_tdata;
                s_axis_tready = m_axis_tready;
            end
            FCS: begin
                m_axis_tvalid = 1'b1;
                
                if (byte_counter == 4'd0)      m_axis_tdata = fcs_byte_0;
                else if (byte_counter == 4'd1) m_axis_tdata = fcs_byte_1;
                else if (byte_counter == 4'd2) m_axis_tdata = fcs_byte_2;
                else                           m_axis_tdata = fcs_byte_3;
                
                // Assert TLAST on the final wax seal byte
                if (byte_counter == 4'd3) m_axis_tlast = 1'b1;
            end
        endcase
    end
endmodule

