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
    .rx_i(rx_i),
    .tx_o(tx_o),
    .rx_int_o(rx_int),
    .tx_int_o(tx_int),
    .err_int_o(err_int),
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

  // Task: send DATA + CRC to UART rx channel
  task send_uart_frame_from_file(input string filename);
    int fd;
    string line;
    bit [15:0] word;
    bit [7:0] data_byte, crc_byte;
    int i;
    static int BIT_TIME = 10417; // Para 9600 bps com clock de 100 MHz

    fd = $fopen(filename, "r");
    if (fd == 0) begin
      $fatal("Erro ao abrir o arquivo %s", filename);
    end

    while (!$feof(fd)) begin
      void'($fgets(line, fd));
      if ($sscanf(line, "%h", word) != 1) continue;

      data_byte = word[15:8];
      crc_byte  = word[7:0];

      // Start Bit
      rx_i = 1'b0;
      repeat (BIT_TIME) @(posedge clk);

      for (i = 0; i < 8; i++) begin
        rx_i = data_byte[i];
        repeat (BIT_TIME) @(posedge clk);
      end

      for (i = 0; i < 8; i++) begin
        rx_i = crc_byte[i];
        repeat (BIT_TIME) @(posedge clk);
      end

      // Stop Bit
      rx_i = 1'b1;
      repeat (BIT_TIME) @(posedge clk);

      // Read RX Data Register
      cfg_addr_i = UART_RX_DATA;
      cfg_we = 1'b0;
      cfg_cs = 1'b1;

      // Wait some time
      repeat (2) @(posedge clk);

      // Assertion on Data
      
      assert (cfg_data_o[7:0] == data_byte) $display("Dado recebido: %x\n", cfg_data_o[7:0]);
      else $error("Err: Expected to receive %x and got %x \n",data_byte,  cfg_data_o[7:0]);

      // Wait some time
      repeat (2) @(posedge clk);

      // Idle for 2 bit times
      repeat (2 * BIT_TIME) @(posedge clk);
    end

    $fclose(fd);
  endtask

  // Stimulus
  initial begin
    // Reset
    rst = 1'b1;
    cfg_we = 'h0;
    cfg_cs = 'h0;
    cfg_addr_i = 'h0;
    cfg_data_i = 'h0;
    rx_i = 1'b1;

    repeat (5) @(posedge clk);
    rst = 1'b0;

    // Set Baud Rate
    uart_write(5'b00000, {16'd10416, 13'd0, 1'b1, 1'b1, 1'b1});

    // Send byte: 0x55 (01010101)
//    uart_write(5'b00010, 32'h00000055);  // TX data
    //uart_write(5'b00001, 32'h00000001);  // TX start (CMD)


    //uart_write(5'b00001, 32'h00000001);  // TX start (CMD)
    send_uart_frame_from_file("frame_crc.txt");
    //repeat (600000) @(posedge clk);
    
    $finish;
  end

endmodule