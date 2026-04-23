`timescale 1ns / 1ps
module sync_fifo #(parameter int DATA_WIDTH = 8, parameter int DEPTH = 8, localparam int ADDR_W = $clog2(DEPTH)) (
    input  logic clk, rst_n, wr_en, rd_en,
    input  logic [DATA_WIDTH-1:0] wr_data,
    output logic [DATA_WIDTH-1:0] rd_data,
    output logic full, empty,
    output logic [ADDR_W:0] count
);
    logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    logic [ADDR_W-1:0] wptr, rptr;
    assign full = (count == DEPTH[ADDR_W:0]);
    assign empty = (count == '0);
    assign rd_data = mem[rptr];
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin wptr <= '0; rptr <= '0; count <= '0; end
        else begin
            if (wr_en && !full) begin mem[wptr] <= wr_data; wptr <= wptr + 1'b1; end
            if (rd_en && !empty) rptr <= rptr + 1'b1;
            case ({wr_en && !full, rd_en && !empty})
                2'b10: count <= count + 1'b1;
                2'b01: count <= count - 1'b1;
                default: count <= count;
            endcase
        end
    end
endmodule
