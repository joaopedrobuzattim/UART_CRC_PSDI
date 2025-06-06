module uart_baud_generator (
    input  logic        clk_i,
    input  logic        rst_i,
    input  logic [15:0] baud_rate_value_i,
    output logic        trigger_tx_o,
    output logic        trigger_rx_o
);

    logic [15:0] counter;

always_ff @(posedge clk_i, posedge rst_i) begin
    if (rst_i) begin
        counter       <= 16'd0;
        trigger_tx_o  <= 1'b0;
        trigger_rx_o  <= 1'b0;
    end else begin
        if (counter == baud_rate_value_i) begin
            trigger_tx_o <= 1'b1;
            counter      <= 16'd0;
        end else if (counter == (baud_rate_value_i >> 1)) begin
            trigger_rx_o <= 1'b1;
            counter      <= counter + 16'd1;
        end else begin
            counter <= counter + 16'd1;
            trigger_tx_o <= 1'b0;
            trigger_rx_o <= 1'b0;
        end
    end
end

endmodule