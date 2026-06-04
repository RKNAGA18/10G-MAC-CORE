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

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= IDLE;
            byte_counter  <= '0;
        end else begin
            if (m_axis_tready || current_state == IDLE) begin
                current_state <= next_state;
                
                if (current_state == PREAMBLE || current_state == IPG) begin
                    byte_counter <= byte_counter + 1;
                end else begin
                    byte_counter <= '0;
                end
            end
        end
    end

    always_comb begin
        next_state = current_state;

        case (current_state)
            IDLE:     if (s_axis_tvalid) next_state = PREAMBLE;
            PREAMBLE: if (byte_counter == 4'd6) next_state = SFD;
            SFD:      next_state = DATA;
            DATA:     if (s_axis_tvalid && s_axis_tready && s_axis_tlast) next_state = FCS;
            FCS:      next_state = IPG;
            IPG:      if (byte_counter == 4'd11) next_state = IDLE;
            default:  next_state = IDLE;
        endcase
    end

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
        endcase
    end
endmodule
    state_t current_state, next_state;
    logic [3:0] byte_counter;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= IDLE;
            byte_counter  <= '0;
        end else begin
            if (m_axis_tready || current_state == IDLE) begin
                current_state <= next_state;
                
                if (current_state == PREAMBLE || current_state == IPG) begin
                    byte_counter <= byte_counter + 1;
                end else begin
                    byte_counter <= '0;
                end
            end
        end
    end

    always_comb begin
        next_state = current_state;

        case (current_state)
            IDLE:     if (s_axis_tvalid) next_state = PREAMBLE;
            PREAMBLE: if (byte_counter == 4'd6) next_state = SFD;
            SFD:      next_state = DATA;
            DATA:     if (s_axis_tvalid && s_axis_tready && s_axis_tlast) next_state = FCS;
            FCS:      next_state = IPG;
            IPG:      if (byte_counter == 4'd11) next_state = IDLE;
            default:  next_state = IDLE;
        endcase
    end

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
        endcase
    end
endmodule
