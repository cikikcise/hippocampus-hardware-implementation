`timescale 1ns / 1ps

module Adder_Tree_8in(
    input wire clk,
    input wire rst,
    input wire signed [19:0] g1, g2, g3, g4, g5, g6, g7, g8,
    output reg signed [19:0] g_total
);

    always @(posedge clk) begin
        if (rst) 
            g_total <= 0;
        else 
            g_total <= g1 + g2 + g3 + g4 + g5 + g6 + g7 + g8;
    end

endmodule
