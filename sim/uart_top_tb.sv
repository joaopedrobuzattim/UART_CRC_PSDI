module uart_top_tb;

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
  logic        rx_int;
  logic        tx_int;
  logic        err_int;

  // Error Counter
  logic [31:0] error_counter;
  logic [31:0] rx_counter;
  logic        reset_error_counter;
  logic        reset_rx_counter;

  // File Descriptor
  int fd;

  // Clock generation
  initial clk = 0;
  always #5 clk = ~clk;  // 100 MHz

  // DUT instantiation
  uart_top dut (
    .clk(clk),
    .rst(rst),
    .rx_i(rx_i),
    .tx_o(tx_o),
    .rx_int_o(rx_int),
    .tx_int_o(tx_int),
    .err_int_o(err_int),
    .cfg_we_i(cfg_we),
    .cfg_cs_i(cfg_cs),
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

  // Task: send UART CRC FRAME from txt file to UART rx channel
  task send_uart_crc_frame_from_file(input string filename);
    int fd;
    string line;
    bit [15:0] word;
    bit [7:0] data_byte, crc_byte;
    int i;
    static int BIT_TIME = 10417;

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

      // Idle for 2 bit times
      repeat (2 * BIT_TIME) @(posedge clk);
    end
  endtask

    // Task: send UART FRAME from txt file to UART rx channel
  task send_uart_frame_from_file(input string filename);
    int fd;
    string line;
    bit [11:0] word;
    bit [7:0] data_byte;
    bit       pairity_bit;
    int i;
    static int BIT_TIME = 10417;

    fd = $fopen(filename, "r");
    if (fd == 0) begin
      $fatal("Erro ao abrir o arquivo %s", filename);
    end

    while (!$feof(fd)) begin
      void'($fgets(line, fd));
      if ($sscanf(line, "%h", word) != 1) continue;

      data_byte    = word[11:4];
      pairity_bit  = word[0];

      // Start Bit
      rx_i = 1'b0;
      repeat (BIT_TIME) @(posedge clk);

      // Data
      for (i = 0; i < 8; i++) begin
        rx_i = data_byte[i];
        repeat (BIT_TIME) @(posedge clk);
      end

      // Pairity Bit
      rx_i = pairity_bit;
      repeat (BIT_TIME) @(posedge clk);

      // Stop Bit
      rx_i = 1'b1;
      repeat (BIT_TIME) @(posedge clk);

      // Idle for 2 bit times
      repeat (2 * BIT_TIME) @(posedge clk);
    end
  endtask

  // Stimulus
  initial begin
    // Reset
    rst = 1'b1;
    reset_error_counter = 1'b1;
    reset_rx_counter = 1'b1;
    cfg_we = 'h0;
    cfg_cs = 'h0;
    cfg_addr_i = 'h0;
    cfg_data_i = 'h0;
    rx_i = 1'b1;

    repeat (5) @(posedge clk);
    rst = 1'b0;
    reset_error_counter = 1'b0;
    reset_rx_counter = 1'b0;

    // Set Baud Rate
    uart_write(5'b00000, {16'd10416, 13'd0, 1'b1, 1'b1, 1'b0});

    // Send byte: 0x55 (01010101)
    //    uart_write(5'b00010, 32'h00000055);  // TX data
    //uart_write(5'b00001, 32'h00000001);  // TX start (CMD)


    //uart_write(5'b00001, 32'h00000001);  // TX start (CMD)
    //send_uart_frame_from_file("incorrect_crc.txt");
    send_uart_frame_from_file("correct_pairity_bit.txt");
    fd = $fopen ("report_pairity_bit_correct.txt", "w");

    $fwrite(fd,"Amount of error detections: %d\nAmount of successful receive: %d", error_counter, rx_counter);
    $fclose(fd);

    reset_error_counter = 1'b1;
    reset_rx_counter = 1'b1;
    repeat (5) @(posedge clk);
    reset_error_counter = 1'b0;
    reset_rx_counter = 1'b0;
    repeat (5) @(posedge clk);

    send_uart_frame_from_file("incorrect_pairity_bit.txt");
    fd = $fopen ("report_pairity_bit_incorrect.txt", "w");
    $fwrite(fd,"Amount of error detections: %d\nAmount of successful receive: %d", error_counter, rx_counter);
    $fclose(fd);

    reset_error_counter = 1'b1;
    rst = 1'b1;
    reset_rx_counter = 1'b1;
    repeat (5) @(posedge clk);
    rst = 1'b0;
    reset_error_counter = 1'b0;
    reset_rx_counter = 1'b0;
    repeat (5) @(posedge clk);
    uart_write(5'b00000, {16'd10416, 13'd0, 1'b1, 1'b1, 1'b1});


    send_uart_crc_frame_from_file("correct_crc.txt");
    fd = $fopen ("report_crc_correct.txt", "w");
    $fwrite(fd,"Amount of error detections: %d\nAmount of successful receive: %d", error_counter, rx_counter);
    $fclose(fd);
    
    reset_error_counter = 1'b1;
    reset_rx_counter = 1'b1;
    repeat (5) @(posedge clk);
    reset_error_counter = 1'b0;
    reset_rx_counter = 1'b0;
    repeat (5) @(posedge clk);

    send_uart_crc_frame_from_file("incorrect_crc.txt");
    fd = $fopen ("report_crc_incorrect.txt", "w");
    $fwrite(fd,"Amount of error detections: %d\nAmount of successful receive: %d", error_counter, rx_counter);
    $fclose(fd);

    $finish;
  end

  // Detecting error interruptions (sync reset)
  always_ff @(posedge clk) begin : error_interruption_counter
    if(reset_error_counter) begin
      error_counter <= 'h0;
    end else if (err_int) begin
      error_counter <= error_counter + 1'b1;
    end
  end

  // Detecting successful rx (sync reset)
  always_ff @(posedge clk) begin : rx_interruption_counter
    if(reset_rx_counter) begin
      rx_counter <= 'h0;
    end else if (rx_int) begin
      rx_counter <= rx_counter + 1'b1;
    end
  end
  

endmodule