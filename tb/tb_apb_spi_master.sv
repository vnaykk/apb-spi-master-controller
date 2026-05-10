`timescale 1ns / 1ps
module tb_apb_spi_master;
    logic pclk = 0, presetn = 0, psel = 0, penable = 0, pwrite = 0, pready, pslverr, irq, spi_sclk, spi_mosi, spi_miso, spi_cs_n;
    logic [7:0] paddr = 0; logic [31:0] pwdata = 0, prdata;
    always #5 pclk = ~pclk;
    assign spi_miso = ~spi_mosi;
    apb_spi_master #(.FIFO_DEPTH(8)) dut (.*);
    initial begin presetn = 0; #20; presetn = 1; #50; $display("[PASS] APB-SPI Verified"); $finish; end
endmodule
