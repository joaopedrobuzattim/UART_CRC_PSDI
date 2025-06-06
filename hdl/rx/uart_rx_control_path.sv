module uart_rx_control_path (
    input       clk_i,
    input       rst_i,

    input        sampled_start_i,
    input        trigger_i,
    input        crc_en_i,
    input [4:0]  bit_cnt_i,

    output       is_rx_idle_o,
    output       is_rx_data_o,
    output       is_rx_pairity_o,
    output       is_rx_crc_o,
    output       is_rx_stop_o,
    
    output       changed_rx_state_o
);


// ############################################################
// ## States
// ############################################################
typedef enum logic [2:0] {
    RX_IDLE,
    RX_DATA_BITS,
    RX_PARITY_BIT,
    RX_CRC,
    RX_STOP_BIT
} t_rx_states;


t_rx_states next_state, current_state;

// ############################################################
// ## State Memory
// ############################################################
always_ff @(posedge clk_i, posedge rst_i) begin
    if (rst_i)
        current_state <= RX_IDLE;
    else if(trigger_i)
        current_state <= next_state;
end


// ############################################################
// ## Next State Logic
// ############################################################
always_comb begin
    next_state <= current_state;
    case (current_state)
        RX_IDLE: begin
            if(sampled_start_i == 1'b1) begin
                next_state <= RX_DATA_BITS;
            end
        end
        RX_DATA_BITS: begin
            if(bit_cnt_i == 5'h7) begin
                if(crc_en_i == 1'b1) begin
                    next_state <= RX_CRC;
                end else begin
                    next_state <= RX_PARITY_BIT;
                end
            end
        end
        RX_PARITY_BIT: begin
            if(bit_cnt_i == 5'b1) begin
                next_state <= RX_STOP_BIT;
            end
        end
        RX_CRC: begin
            if(bit_cnt_i == 5'h7) begin
                next_state <= RX_STOP_BIT;
            end
        end
        RX_STOP_BIT: begin
            if(bit_cnt_i == 5'b1) begin
                next_state <= RX_IDLE;
            end
        end
        default: next_state <= RX_IDLE;
    endcase
end

// ############################################################
// ## Current State Outputs
// ############################################################
assign is_rx_idle_o       = current_state == RX_IDLE;
assign is_rx_data_o       = current_state == RX_DATA_BITS;
assign is_rx_pairity_o    = current_state == RX_PARITY_BIT;   
assign is_rx_crc_o        = current_state == RX_CRC;
assign is_rx_stop_o       = current_state == RX_STOP_BIT;

assign changed_rx_state_o = (current_state != next_state);

endmodule