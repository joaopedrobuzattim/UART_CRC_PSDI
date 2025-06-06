module uart_tx (
    input        clk_i,
    input        rst_i,

    input  [7:0] data_i,
    input        crc_en_i,
    input        tx_start_cmd_i,
    input        trigger_i,

    output       tx_o
);


logic is_tx_idle;
logic is_tx_start;
logic is_tx_data;
logic is_tx_pairity;
logic is_tx_crc;
logic is_tx_stop;
logic changed_tx_state;
logic [4:0] bit_cnt; 
logic start_tx;

// ############################################################
// ## Data Path
// ############################################################
uart_tx_data_path i_uart_tx_data_path(
    .clk_i(clk_i),
    .rst_i(rst_i),

    .data_i(data_i),
    .crc_en_i(crc_en_i),
    .trgger_i(trigger_i),
    .tx_start_cmd_i(tx_start_cmd_i),
    .changed_tx_state_i(changed_tx_state),
    .is_tx_idle_i(is_tx_idle),
    .is_tx_start_i(is_tx_start),
    .is_tx_data_i(is_tx_data),
    .is_tx_crc_i(is_tx_crc),
    .is_tx_pairity_i(is_tx_pairity),
    .is_tx_stop_i(is_tx_stop),
    .start_tx_o(start_tx),
    .tx_o(tx_o),
    .bit_cnt_o(bit_cnt)
);

// ############################################################
// ## Control Path
// ############################################################
uart_tx_control_path i_uart_tx_control_path (
    .clk_i(clk_i),
    .rst_i(rst_i),

    .tx_start_i(start_tx),
    .trgger_i(trigger_i),
    .crc_en_i(crc_en_i),
    .bit_cnt_i(bit_cnt),

    .is_tx_idle_o(is_tx_idle),
    .is_tx_start_o(is_tx_start),
    .is_tx_data_o(is_tx_data),
    .is_tx_pairity_o(is_tx_pairity),
    .is_tx_crc_o(is_tx_crc),
    .is_tx_stop_o(is_tx_stop),
    
    .changed_tx_state_o(changed_tx_state)
);
endmodule