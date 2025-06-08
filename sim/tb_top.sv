module tb_top;

  // Clock and reset
  logic clk;
  logic rst;

  // Bus interface
  logic        rx_i;
  logic        tx_o;
  logic        cfg_we;
  logic        cfg_cs;
  logic [31:0] cfg_data_i;
  logic [31:0] cfg_data_o;
  logic [4:0]  cfg_addr_i;
  logic        rx_data_valid_o;
  logic [7:0]  rx_data_o;
  logic [7:0]  tx_data_i;
  logic       rx_int;
  logic       tx_int;
  logic       err_int;

  // Clock generation
  initial clk = 0;
  always #5 clk = ~clk;  // 100 MHz

  // DUT instantiation
  uart_top dut (
    .clk(clk),
    .rst_i(rst),
    .rx_i(tx_o),
    .tx_o(tx_o),
    .rx_data_valid_o(rx_data_valid_o),
    .rx_data_o(rx_data_o),
    .rx_int_o(rx_int),
    .tx_int_o(tx_int),
    .err_int_o(err_int),
    .tx_data_i(tx_data_i),
    .cfg_we(cfg_we),
    .cfg_cs(cfg_cs),
    .cfg_data_i(cfg_data_i),
    .cfg_data_o(cfg_data_o),
    .cfg_addr_i(cfg_addr_i)
  );

  // Task: write to UART register
  task uart_write(input [4:0] addr, input [31:0] data);
    begin
      cfg_addr_i = addr;
      cfg_data_i = data;
      cfg_we = 1'b1;
      cfg_cs = 1'b1;
      @(posedge clk);
      cfg_we = 1'b0;
      cfg_cs = 1'b0;
    end
  endtask

  // Stimulus
  initial begin
    // Reset
    rst = 1'b1;
    cfg_we = 0;
    cfg_cs = 0;
    cfg_addr_i = 0;
    cfg_data_i = 0;
    rx_i = 1'b1;
    tx_data_i = 8'h00;
    repeat (5) @(posedge clk);
    rst = 1'b0;

    // Configure UART: enable TX/RX and set clock divider to 10
    uart_write(5'b00000, {16'd10416, 13'd0, 1'b1, 1'b1, 1'b1});

    // Send byte: 0x55 (01010101)
    uart_write(5'b00010, 32'h00000055);  // TX data
    uart_write(5'b00001, 32'h00000001);  // TX start (CMD)

    // Wait some time for transmission to complete
    repeat (600000) @(posedge clk);

    uart_write(5'b00001, 32'h00000001);  // TX start (CMD)
    repeat (600000) @(posedge clk);
    
    $finish;
  end

endmodule