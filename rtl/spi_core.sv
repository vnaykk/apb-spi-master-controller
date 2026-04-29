`timescale 1ns / 1ps
module spi_core (
    input  logic clk, rst_n, enable, tx_valid, spi_miso,
    input  logic [7:0] clk_div, tx_data,
    output logic tx_ready, rx_valid, busy, spi_sclk, spi_mosi, spi_cs_n,
    output logic [7:0] rx_data
);
    typedef enum logic [1:0] { ST_IDLE = 2'b00, ST_TRANSFER = 2'b01, ST_FINISH = 2'b10 } state_t;
    state_t state;
    logic [7:0] clk_cnt, shreg_tx, shreg_rx;
    logic [2:0] bit_idx;
    logic sclk_reg;
    assign spi_sclk = sclk_reg; assign spi_mosi = shreg_tx[7]; assign rx_data = shreg_rx; assign busy = (state != ST_IDLE);
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= ST_IDLE; clk_cnt <= '0; bit_idx <= '0; shreg_tx <= '0; shreg_rx <= '0;
            sclk_reg <= 1'b0; spi_cs_n <= 1'b1; tx_ready <= 1'b0; rx_valid <= 1'b0;
        end else begin
            tx_ready <= 1'b0; rx_valid <= 1'b0;
            case (state)
                ST_IDLE: begin
                    sclk_reg <= 1'b0; spi_cs_n <= 1'b1;
                    if (enable && tx_valid) begin
                        shreg_tx <= tx_data; spi_cs_n <= 1'b0; tx_ready <= 1'b1; clk_cnt <= '0; bit_idx <= 3'd7; state <= ST_TRANSFER;
                    end
                end
                ST_TRANSFER: begin
                    if (clk_cnt == clk_div) begin
                        clk_cnt <= '0; sclk_reg <= ~sclk_reg;
                        if (!sclk_reg) shreg_rx <= {shreg_rx[6:0], spi_miso};
                        else begin
                            shreg_tx <= {shreg_tx[6:0], 1'b0};
                            if (bit_idx == 3'd0) state <= ST_FINISH; else bit_idx <= bit_idx - 1'b1;
                        end
                    end else clk_cnt <= clk_cnt + 1'b1;
                end
                ST_FINISH: begin sclk_reg <= 1'b0; spi_cs_n <= 1'b1; rx_valid <= 1'b1; state <= ST_IDLE; end
                default: state <= ST_IDLE;
            endcase
        end
    end
endmodule
