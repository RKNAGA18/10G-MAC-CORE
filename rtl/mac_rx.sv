module mac_rx #(
    parameter DATA_WIDTH = 8
)(
    input  logic clk,
    input  logic rst_n,

    // SLAVE 
    input  logic [DATA_WIDTH-1:0] s_axis_tdata,
    input  logic                  s_axis_tvalid,
    input  logic                  s_axis_tlast,
    output logic                  s_axis_tready,

    // MASTER 
    output logic [DATA_WIDTH-1:0] m_axis_tdata,
    output logic                  m_axis_tvalid,
    output logic                  m_axis_tlast,
    input  logic                  m_axis_tready,
    
    output logic                  rx_error
);

    typedef enum logic [2:0] {
        HUNT      = 3'd0,
        PREAMBLE  = 3'd1,
        DATA      = 3'd2,
        CHECK_FCS = 3'd3
    } state_t;

    state_t current_state, next_state;
    logic [3:0]  byte_counter;
    logic [31:0] crc_reg, next_crc;
    logic [31:0] received_fcs;

    crc32_d8 crc_engine (
        .data(s_axis_tdata),
        .crc_in(crc_reg),
        .crc_out(next_crc)
    );

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= HUNT;
            byte_counter  <= 4'd0;
            crc_reg       <= 32'hFFFFFFFF;
            received_fcs  <= 32'h00000000;
            rx_error      <= 1'b0;
        end else begin
            current_state <= next_state;

            if (current_state == CHECK_FCS) byte_counter <= byte_counter + 1;
            else byte_counter <= 4'd0;

            if (current_state == HUNT) begin
                crc_reg  <= 32'hFFFFFFFF; 
                // We REMOVED the rx_error clear from here!
            end else if (current_state == DATA && s_axis_tvalid && s_axis_tready) begin
                crc_reg <= next_crc;
            end

            // Verification
            if (current_state == CHECK_FCS && s_axis_tvalid) begin
                received_fcs <= {received_fcs[23:0], s_axis_tdata}; 
                if (byte_counter == 4'd3) begin
                    if ({received_fcs[23:0], s_axis_tdata} != ~crc_reg) begin
                        rx_error <= 1'b1; // THE STICKY ERROR FLAG
                    end
                end
            end
            
            if (current_state == HUNT && s_axis_tvalid && s_axis_tdata == 8'h55) begin
                rx_error <= 1'b0;
            end
        end
    end

    always_comb begin
        next_state = current_state; 
        case (current_state)
            HUNT:      if (s_axis_tvalid && s_axis_tdata == 8'h55) next_state = PREAMBLE;
            PREAMBLE:  begin
                if (s_axis_tvalid) begin
                    if (s_axis_tdata == 8'hD5) next_state = DATA;
                    else if (s_axis_tdata != 8'h55) next_state = HUNT;
                end
            end
            DATA:      if (s_axis_tvalid && s_axis_tlast) next_state = CHECK_FCS;
            CHECK_FCS: if (byte_counter == 4'd3) next_state = HUNT;
            default:   next_state = HUNT;
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
