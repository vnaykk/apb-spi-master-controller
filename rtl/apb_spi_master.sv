`timescale 1ns / 1ps
module apb_spi_master #(parameter int FIFO_DEPTH = 8) (
    input  logic pclk, presetn, psel, penable, pwrite, spi_miso,
    input  logic [7:0] paddr,
    input  logic [31:0] pwdata,
    output logic [31:0] prdata,
    output logic pready, pslverr, irq, spi_sclk, spi_mosi, spi_cs_n
);
    localparam logic [7:0] REG_CTRL = 8'h00, REG_STATUS = 8'h04, REG_CLK_DIV = 8'h08, REG_TX_DATA = 8'h0C, REG_RX_DATA = 8'h10;
    logic ctrl_en, ctrl_irq_en, apb_wr, apb_rd, tx_wr_en, tx_rd_en, tx_full, tx_empty, rx_wr_en, rx_rd_en, rx_full, rx_empty, core_busy;
    logic [7:0] reg_clk_div, tx_fifo_dout, rx_fifo_din, rx_fifo_dout;
    logic [3:0] tx_count, rx_count;
    assign pready = 1'b1; assign pslverr = 1'b0;
    assign apb_wr = psel & penable & pwrite; assign apb_rd = psel & ~pwrite;
    assign tx_wr_en = apb_wr & (paddr == REG_TX_DATA);
    assign rx_rd_en = psel & penable & ~pwrite & (paddr == REG_RX_DATA);
    assign irq = ctrl_irq_en & ~rx_empty;
    always_ff @(posedge pclk or negedge presetn) begin
        if (!presetn) begin ctrl_en <= 1'b0; ctrl_irq_en <= 1'b0; reg_clk_div <= 8'd2; end
        else if (apb_wr) begin
            if (paddr == REG_CTRL) {ctrl_irq_en, ctrl_en} <= pwdata[1:0];
            else if (paddr == REG_CLK_DIV) reg_clk_div <= pwdata[7:0];
        end
    end
    always_comb begin
        prdata = 32'h0;
        if (apb_rd) begin
            case (paddr)
                REG_CTRL:    prdata = {30'h0, ctrl_irq_en, ctrl_en};
                REG_STATUS:  prdata = {27'h0, rx_empty, rx_full, tx_empty, tx_full, core_busy};
                REG_CLK_DIV: prdata = {24'h0, reg_clk_div};
                REG_RX_DATA: prdata = {24'h0, rx_fifo_dout};
                default:     prdata = 32'h0;
            endcase
        end
    end
    sync_fifo #(.DATA_WIDTH(8), .DEPTH(FIFO_DEPTH)) u_tx_fifo (.clk(pclk), .rst_n(presetn), .wr_en(tx_wr_en), .wr_data(pwdata[7:0]), .rd_en(tx_rd_en), .rd_data(tx_fifo_dout), .full(tx_full), .empty(tx_empty), .count(tx_count));
    sync_fifo #(.DATA_WIDTH(8), .DEPTH(FIFO_DEPTH)) u_rx_fifo (.clk(pclk), .rst_n(presetn), .wr_en(rx_wr_en), .wr_data(rx_fifo_din), .rd_en(rx_rd_en), .rd_data(rx_fifo_dout), .full(rx_full), .empty(rx_empty), .count(rx_count));
    spi_core u_spi_core (.clk(pclk), .rst_n(presetn), .enable(ctrl_en), .clk_div(reg_clk_div), .tx_valid(~tx_empty), .tx_data(tx_fifo_dout), .tx_ready(tx_rd_en), .rx_valid(rx_wr_en), .rx_data(rx_fifo_din), .busy(core_busy), .spi_sclk(spi_sclk), .spi_mosi(spi_mosi), .spi_miso(spi_miso), .spi_cs_n(spi_cs_n));
endmodule
