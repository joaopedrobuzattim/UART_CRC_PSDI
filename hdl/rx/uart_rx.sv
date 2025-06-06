module uart_rx (
    input        clk_i,
    input        rst_i,

    input        rx_i,
    input        crc_en_i,
    input        trigger_i,

    output       [7:0] data_o
);


logic is_rx_idle;
logic is_rx_start;
logic is_rx_pairity;
logic is_rx_crc;
logic is_rx_stop;
logic changed_rx_state;
logic [4:0] bit_cnt; 
logic sampled_start;

// ############################################################
// ## Data Path
// ############################################################
uart_rx_data_path i_uart_rx_data_path(
    .clk_i(clk_i),
    .rst_i(rst_i),

    .crc_en_i(crc_en_i),
    .trigger_i(trigger_i),
    .changed_rx_state_i(changed_rx_state),
    .is_rx_idle_i(is_rx_idle),
    .is_rx_data_i(is_rx_data),
    .is_rx_crc_i(is_rx_crc),
    .is_rx_pairity_i(is_rx_pairity),
    .is_rx_stop_i(is_rx_stop),
    .sampled_start_o(sampled_start),
    .rx_i(rx_i),
    .bit_cnt_o(bit_cnt),
    .data_o(data_o)
);

// ############################################################
// ## Control Path
// ############################################################
uart_rx_control_path i_uart_rx_control_path (
    .clk_i(clk_i),
    .rst_i(rst_i),

    .sampled_start_i(sampled_start),
    .trigger_i(trigger_i),
    .crc_en_i(crc_en_i),
    .bit_cnt_i(bit_cnt),

    .is_rx_idle_o(is_rx_idle),
    .is_rx_data_o(is_rx_data),
    .is_rx_pairity_o(is_rx_pairity),
    .is_rx_crc_o(is_rx_crc),
    .is_rx_stop_o(is_rx_stop),
    
    .changed_rx_state_o(changed_rx_state)
);
endmodule