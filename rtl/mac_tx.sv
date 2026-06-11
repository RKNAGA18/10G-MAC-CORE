module mac_tx #(
    parameter DATA_WIDTH = 8
)(
    input  logic clk,
    input  logic rst_n,

    // SLAVE INTERFACE (From Host)
    input  logic [DATA_WIDTH-1:0] s_axis_tdata,
    input  logic                  s_axis_tvalid,
    input  logic                  s_axis_tlast,
    output logic                  s_axis_tready,

    // MASTER INTERFACE (To Network PHY)
    output logic [DATA_WIDTH-1:0] m_axis_tdata,
    output logic                  m_axis_tvalid,
    input  logic                  m_axis_tready
);

    typedef enum logic [2:0] {
        IDLE     = 3'd0,
        PREAMBLE = 3'd1,
        SFD      = 3'd2,
        DATA     = 3'd3,
        FCS      = 3'd4,
        IPG      = 3'd5
    } state_t;

    state_t current_state, next_state;
    logic [3:0] byte_counter;

    // NEW: CRC Registers and Wires
    logic [31:0] crc_reg;
    logic [31:0] next_crc;

    // NEW: Instantiate the Math Engine!
    crc32_d8 crc_engine (
        .data(s_axis_tdata),
        .crc_in(crc_reg),
        .crc_out(next_crc)
    );

    // BLOCK 1: Sequential Logic
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= IDLE;
            byte_counter  <= '0;
            crc_reg       <= 32'hFFFFFFFF; // NEW: Ethernet standard init
        end else begin
            if (m_axis_tready || current_state == IDLE) begin
                current_state <= next_state;
                
                // Counter Management
                if (current_state == PREAMBLE || current_state == FCS || current_state == IPG) begin
                    byte_counter <= byte_counter + 1;
                end else begin
                    byte_counter <= '0;
                end

                // NEW: CRC Math Management
                if (current_state == IDLE) begin
                    crc_reg <= 32'hFFFFFFFF; // Reset for new packet
                end else if (current_state == DATA && s_axis_tvalid && s_axis_tready) begin
                    crc_reg <= next_crc; // Calculate hash on the fly!
                end
            end
        end
    end

    // BLOCK 2: Combinational Logic (Next State)
    always_comb begin
        next_state = current_state;

        case (current_state)
            IDLE:     if (s_axis_tvalid) next_state = PREAMBLE;
            PREAMBLE: if (byte_counter == 4'd6) next_state = SFD;
            SFD:      next_state = DATA;
            DATA:     if (s_axis_tvalid && s_axis_tready && s_axis_tlast) next_state = FCS;
            FCS:      if (byte_counter == 4'd3) next_state = IPG; // NEW: Wait 4 cycles for CRC
            IPG:      if (byte_counter == 4'd11) next_state = IDLE;
            default:  next_state = IDLE;
        endcase
    end

    // BLOCK 3: Output Logic
    always_comb begin
        s_axis_tready = 1'b0;
        m_axis_tvalid = 1'b0;
        m_axis_tdata  = 8'h00;

        case (current_state)
            IDLE: begin
            end
            PREAMBLE: begin
                m_axis_tvalid = 1'b1;
                m_axis_tdata  = 8'h55;
                s_axis_tready = 1'b0;
            end
            SFD: begin
                m_axis_tvalid = 1'b1;
                m_axis_tdata  = 8'hD5;
                s_axis_tready = 1'b0;
            end
            DATA: begin
                m_axis_tvalid = s_axis_tvalid;
                m_axis_tdata  = s_axis_tdata;
                s_axis_tready = m_axis_tready;
            end
            FCS: begin
                // NEW: Transmit the 4-byte Wax Seal!
                m_axis_tvalid = 1'b1;
                s_axis_tready = 1'b0; // Hold host back
                
                // Shift out the inverted CRC bytes sequentially
                case (byte_counter)
                    4'd0: m_axis_tdata = ~crc_reg[31:24];
                    4'd1: m_axis_tdata = ~crc_reg[23:16];
                    4'd2: m_axis_tdata = ~crc_reg[15:8];
                    4'd3: m_axis_tdata = ~crc_reg[7:0];
                    default: m_axis_tdata = 8'h00;
                endcase
            end
        endcase
    end
endmodule
