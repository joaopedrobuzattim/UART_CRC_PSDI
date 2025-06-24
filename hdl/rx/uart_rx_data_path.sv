module uart_rx_data_path (
    input         clk_i,
    input         rst_i,

    input  logic  rx_i,
    input         crc_en_i,
    input         trigger_i,
    input         changed_rx_state_i,
    input         is_rx_idle_i,
    input         is_rx_pairity_i,
    input         is_rx_crc_i,
    input         is_rx_stop_i,
    input         is_rx_data_i,

    output logic  sampled_start_o,
    output [4:0]  bit_cnt_o,
    output logic [7:0]  data_o,
    output logic  rx_int_o,
    output logic  err_int_o
);

    logic [7:0] data_in;
    logic [7:0] crc_in;
    logic       parity_bit_in;
    logic [7:0] calculated_crc;
    logic [4:0] bit_cnt;
    logic [4:0] reverse_count_crc_index;
    logic       parity_bit;
    logic       err;
    logic       success;

    assign reverse_count_crc_index = 5'h7 - bit_cnt;

    // CRC
    uart_crc_gen i_uart_crc_gen (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .initialize_i(is_rx_idle_i  & (~rx_i) & trigger_i),
        .enable_i(crc_en_i & is_rx_crc_i & trigger_i),
        .data_bit_i(data_in[reverse_count_crc_index]),
        .crc_o(calculated_crc)
    );

    // Start Bit
    assign sampled_start_o = is_rx_idle_i  & (~rx_i) & trigger_i; 

    // Error Condition
    assign err =  is_rx_stop_i & trigger_i & ( (crc_en_i & calculated_crc != crc_in ) | (~crc_en_i & parity_bit != parity_bit_in) );

    // Success on RX
    assign success = is_rx_stop_i & trigger_i & ( (crc_en_i & calculated_crc == crc_in ) | (~crc_en_i & parity_bit == parity_bit_in) );

    // Data In (Shift Right Register)
    always_ff @(posedge clk_i, posedge rst_i) begin
        if (rst_i)
            data_in <= '0;
        else if (trigger_i & is_rx_data_i)
            data_in <= {rx_i, data_in[7:1]};
    end

    // CRC In (Shift Right Register)
    always_ff @(posedge clk_i, posedge rst_i) begin
        if (rst_i)
            crc_in <= '0;
        else if (trigger_i & is_rx_crc_i)
            crc_in <= {rx_i, crc_in[7:1]};
    end

    // Parity Bit In
    always_ff @(posedge clk_i, posedge rst_i) begin
        if (rst_i)
            parity_bit_in <= '0;
        else if (trigger_i & is_rx_pairity_i)
            parity_bit_in <= rx_i;
    end

    // Parity Bit Calculation (Odd Parity)
    always_comb begin
        parity_bit = ~(^data_in);
    end
    
        
    
    // Bit Cnt Register Logic
    always_ff @(posedge clk_i, posedge rst_i) begin
        if (rst_i) begin
            bit_cnt   <= 5'd0;
        end else if (changed_rx_state_i & trigger_i) begin
            bit_cnt   <= 5'd0;
        end else if (trigger_i & ~is_rx_idle_i) begin
            bit_cnt   <= bit_cnt + 5'd1;
        end
    end

    // Interrupt generation (1 clk cycle high)
    always_ff @(posedge clk_i, posedge rst_i ) begin
        if (rst_i) begin
            rx_int_o   <= 1'b0;
        end else if (rx_int_o) begin
            rx_int_o   <= 1'b0;
        end else if (success) begin
            rx_int_o   <= 1'b1;
        end
    end

    always_ff @(posedge clk_i, posedge rst_i ) begin
        if (rst_i) begin
            err_int_o   <= 1'b0;
        end else if (err_int_o) begin
            err_int_o   <= 1'b0;
        end else if (err) begin
            err_int_o   <= 1'b1;
        end
    end


    assign bit_cnt_o = bit_cnt;
    assign data_o    = data_in;

endmodule