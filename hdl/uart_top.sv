module uart_top (
    
    // Circuito clk and rest
    input  logic        clk,
    input  logic        rst,

    // Comunication channels TX and RX
    input  logic        rx_i,
    output logic        tx_o,

    // Interruptions
    output       rx_int_o,
    output       tx_int_o,
    output       err_int_o,

    // Register Cfg,
    input  logic        cfg_we_i,
    input  logic        cfg_cs_i,
    input  logic [31:0] cfg_data_i,
    input  logic [4:0]  cfg_addr_i,
    output logic [31:0] cfg_data_o

);


logic [15:0] clock_divider;
logic [7:0]  tx_data;
logic [7:0]  rx_data;
logic        tx_start_cmd;
logic        trigger_tx;
logic        trigger_rx;
logic        rx_en;
logic        tx_en;
logic        crc_en;

// ############################################################
// ## Baud Rate Generator
// ############################################################
uart_baud_generator i_uart_baud_rate (
    .clk_i(clk),
    .rst_i(rst),
    .baud_rate_value_i(clock_divider),
    .trigger_tx_o(trigger_tx),
    .trigger_rx_o(trigger_rx)
);

// ############################################################
// ## Registers
// ############################################################
uart_reg i_uart_registers(
    .clk(clk),
    .rst_i(rst),

    .cfg_we(cfg_we_i),
    .cfg_cs(cfg_cs_i),
    .cfg_data_i(cfg_data_i),
    .cfg_data_o(cfg_data_o),
    .cfg_addr_i(cfg_addr_i),

    .rx_data_i(rx_data),
    .crc_en_o(crc_en),
    .tx_en_o(tx_en),
    .rx_en_o(rx_en),
    .tx_start_cmd_o(tx_start_cmd),
    .clock_divider_o(clock_divider),
    .tx_data_o(tx_data)
);

// ############################################################
// ## Tx
// ############################################################
uart_tx i_uart_tx(
    .clk_i(clk),
    .rst_i(rst),

    .data_i(tx_data),
    .crc_en_i(crc_en),
    .tx_start_cmd_i(tx_start_cmd),
    .trigger_i(trigger_tx),

    .tx_o(tx_o),
    .tx_int_o(tx_int_o)
);

// ############################################################
// ## Rx
// ############################################################
uart_rx i_uart_rx(
    .clk_i(clk),
    .rst_i(rst),

    .rx_i(rx_i),
    .crc_en_i(crc_en),
    .trigger_i(trigger_rx),

    .data_o(rx_data),
    .rx_int_o(rx_int_o),
    .err_int_o(err_int_o)
);


endmodule