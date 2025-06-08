module uart_tx_control_path (
    input       clk_i,
    input       rst_i,

    input        tx_start_i,
    input        trigger_i,
    input        crc_en_i,
    input [4:0]  bit_cnt_i,

    output       is_tx_idle_o,
    output       is_tx_start_o,
    output       is_tx_data_o,
    output       is_tx_pairity_o,
    output       is_tx_crc_o,
    output       is_tx_stop_o,
    
    output       changed_tx_state_o
);


// ############################################################
// ## States
// ############################################################

typedef enum logic [2:0] {
    TX_IDLE,
    TX_START_BIT,
    TX_DATA_BITS,
    TX_PARITY_BIT,
    TX_CRC,
    TX_STOP_BIT
} t_tx_states;


t_tx_states next_state, current_state;

// ############################################################
// ## State Memory
// ############################################################
always_ff @(posedge clk_i, posedge rst_i) begin
    if (rst_i)
        current_state <= TX_IDLE;
    else if(trigger_i)
        current_state <= next_state;
end


// ############################################################
// ## Next State Logic
// ############################################################
always_comb begin
    next_state <= current_state;
    case (current_state)
        TX_IDLE: begin
            if(tx_start_i == 1'b1) begin
                next_state <= TX_START_BIT;
            end
        end
        TX_START_BIT: begin
            next_state <= TX_DATA_BITS;
        end
        TX_DATA_BITS: begin
            if(bit_cnt_i == 5'h7) begin
                if(crc_en_i == 1'b1) begin
                    next_state <= TX_CRC;
                end else begin
                    next_state <= TX_PARITY_BIT;
                end
            end
        end
        TX_PARITY_BIT: begin
            next_state <= TX_STOP_BIT;
        end
        TX_CRC: begin
            if(bit_cnt_i == 5'h7) begin
                next_state <= TX_STOP_BIT;
            end
        end
        TX_STOP_BIT: begin
            next_state <= TX_IDLE;
        end
        default: next_state <= TX_IDLE;
    endcase
end

// ############################################################
// ## Current State Outputs
// ############################################################
assign is_tx_idle_o       = current_state == TX_IDLE;
assign is_tx_start_o      = current_state == TX_START_BIT;  
assign is_tx_data_o       = current_state == TX_DATA_BITS;
assign is_tx_pairity_o    = current_state == TX_PARITY_BIT;   
assign is_tx_crc_o        = current_state == TX_CRC;
assign is_tx_stop_o       = current_state == TX_STOP_BIT;

assign changed_tx_state_o = (current_state != next_state);

endmodule