localparam UART_OPERATION_CONFIG = 5'b00000;
localparam UART_CMD              = 5'b00001;
localparam UART_TX_DATA          = 5'b00010;
localparam UART_RX_DATA          = 5'b00011;

module uart_reg (
    input  logic        clk,
    input  logic        rst_i,

    input  logic        cfg_we,
    input  logic        cfg_cs,
    input  logic [31:0] cfg_data_i,
    input  logic [4:0]  cfg_addr_i,

    input        [7:0]  rx_data_i,

    output logic        tx_en_o,
    output logic        rx_en_o,
    output logic        crc_en_o,
    output logic [15:0] clock_divider_o,
    output logic        tx_start_cmd_o,
    output logic [7:0]  tx_data_o,
    output logic [31:0] cfg_data_o
);


    logic        r_uart_crc_en;
    logic  [7:0] r_uart_tx_data;
    logic        r_uart_tx_en;
    logic        r_uart_rx_en;
    logic [15:0] r_uart_clock_divider;
    logic        r_uart_tx_cmd;
    logic  [4:0] rd_addr;
    
    assign rd_addr = (cfg_cs &  ~cfg_we) ? cfg_addr_i : 5'h0;
    
    always_ff @( posedge clk, posedge rst_i ) begin
        if (rst_i) begin
            r_uart_crc_en          <= 'h0; 
            r_uart_tx_data         <= 'h0;  
            r_uart_tx_en           <= 'h0; 
            r_uart_rx_en           <= 'h0; 
            r_uart_clock_divider   <= 'h0; 
        end else begin
            if (cfg_cs & cfg_we) begin
                case(cfg_addr_i)
                    UART_OPERATION_CONFIG: begin
                        r_uart_crc_en          <= cfg_data_i[0];
                        r_uart_tx_en           <= cfg_data_i[1];
                        r_uart_rx_en           <= cfg_data_i[2];
                        r_uart_clock_divider   <= cfg_data_i[31:16];
                    end
                    UART_TX_DATA: begin
                        r_uart_tx_data         <= cfg_data_i[7:0];
                    end
                endcase
            end
        end
    end
   
    // Sync and Async Reset
    always_ff @(posedge clk, posedge rst_i ) begin
        if (rst_i) begin
            r_uart_tx_cmd <= 'h0;
        end else if ( r_uart_tx_cmd == 1'b1) begin
            r_uart_tx_cmd <= 'h0;
        end else if (cfg_cs & cfg_we & cfg_addr_i == UART_CMD) begin
            r_uart_tx_cmd <= cfg_data_i[0];
        end      
    end

    // Register Read
    always_comb
    begin
    cfg_data_o = 32'h0;
    case (rd_addr)
        UART_OPERATION_CONFIG  : cfg_data_o                 = {r_uart_clock_divider, 13'h0, r_uart_rx_en, r_uart_tx_en, r_uart_crc_en};
        UART_TX_DATA           : cfg_data_o                 = {24'h0, r_uart_tx_data};
        UART_RX_DATA           : cfg_data_o                 = {24'h0, rx_data_i};
    endcase
    end


    // Output 
    assign tx_en_o = r_uart_tx_en;
    assign rx_en_o = r_uart_rx_en;
    assign crc_en_o = r_uart_crc_en;
    assign clock_divider_o = r_uart_clock_divider;
    assign tx_start_cmd_o = r_uart_tx_cmd;
    assign tx_data_o = r_uart_tx_data;

endmodule


