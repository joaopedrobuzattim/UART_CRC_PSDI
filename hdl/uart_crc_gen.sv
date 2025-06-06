module uart_crc_gen (
    input  logic        clk_i,
    input  logic        rst_i,
    input  logic        enable_i,
    input  logic        initialize_i,
    input  logic        data_bit_i,
    output logic [7:0]  crc_o
);
    parameter CRC_POL = 8'h07;

    logic [7:0] crc_r;
    

    always_ff @(posedge clk_i, posedge rst_i) begin
        if (rst_i)
            crc_r <= 8'h00;
        else if (initialize_i)
            crc_r <= 8'h00;
        else if (enable_i) begin
            if (crc_r[7] ^ data_bit_i)
                crc_r <= (crc_r << 1) ^ CRC_POL;
            else
                crc_r <= crc_r << 1;
        end
    end

    assign crc_o = crc_r;

endmodule