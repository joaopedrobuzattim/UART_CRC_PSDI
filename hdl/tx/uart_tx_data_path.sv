module uart_tx_data_path (
    input         clk_i,
    input         rst_i,

    input  [7:0]  data_i,
    input         crc_en_i,
    input         trigger_i,
    input         tx_start_cmd_i,
    input         changed_tx_state_i,
    input         is_tx_idle_i,
    input         is_tx_start_i,
    input         is_tx_pairity_i,
    input         is_tx_crc_i,
    input         is_tx_stop_i,
    input         is_tx_data_i,

    output logic  tx_o,
    output logic  start_tx_o,
    output [4:0]  bit_cnt_o,
    output logic  tx_int_o
);

    logic [7:0] crc_data;
    logic [4:0] bit_cnt;
    logic       parity_bit;
    logic [7:0] tx_data_inv;
    logic       success;

    // Success on RX
    assign success = is_tx_stop_i & trigger_i;

    // UART TX Data Inverted for CRC input
    assign tx_data_inv = {<<{data_i}}; 

    // CRC
    uart_crc_gen i_uart_crc_gen (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .initialize_i(is_tx_start_i),
        .enable_i(crc_en_i & is_tx_data_i & trigger_i),
        .data_bit_i(tx_data_inv[bit_cnt]),
        .crc_o(crc_data)
    );

    // Triggered Start
    always_ff @(posedge clk_i, posedge rst_i ) begin
        if (rst_i) begin
            start_tx_o <= 1'b0;
        end else if(start_tx_o == 1'b1 && trigger_i) begin
            start_tx_o <= 1'b0;
        end else if(tx_start_cmd_i)
            start_tx_o <= 1'b1;
    end

    // Bit Cnt Register Logic
    always_ff @(posedge clk_i, posedge rst_i) begin
        if (rst_i) begin
            bit_cnt   <= 5'd0;
        end else if (changed_tx_state_i & trigger_i) begin
            bit_cnt   <= 5'd0;
        end else if (trigger_i & ~is_tx_idle_i) begin
            bit_cnt   <= bit_cnt + 5'd1;
        end
    end

    // Parity Bit Calculation (Even parity)
    always_comb begin
        parity_bit = ^data_i;
    end

    // Output Mux
    always_comb begin
        if (is_tx_start_i)
            tx_o = 1'b0;
        else if (is_tx_data_i)
            tx_o = data_i[bit_cnt];
        else if (is_tx_pairity_i)
            tx_o = parity_bit;
        else if (is_tx_crc_i)
            tx_o = crc_data[bit_cnt];
        else if (is_tx_stop_i)
            tx_o = 1'b1;
        else 
            tx_o = 1'b1;
    end

    // Interrupt generation (1 clk cycle high)
    always_ff @(posedge clk_i, posedge rst_i ) begin
        if (rst_i) begin
            tx_int_o   <= 1'b0;
        end else if (tx_int_o) begin
            tx_int_o   <= 1'b0;
        end else if (success) begin
            tx_int_o   <= 1'b1;
        end
    end

    assign bit_cnt_o = bit_cnt;

endmodule