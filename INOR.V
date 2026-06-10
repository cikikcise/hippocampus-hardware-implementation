`timescale 1ns / 1ps

module INOR(
    input wire clk, rst,
    input wire signed [19:0] g1, g2, g3, g4, g5, g6, g7, g8,
    output reg spike
    );
    
    wire signed [19:0] total_g;
    reg spike_raw;      
    reg spike_delay; 
    
    Adder_Tree_8in adder_inst (
        .clk(clk), .rst(rst),
        .g1(g1), .g2(g2), .g3(g3), .g4(g4),
        .g5(g5), .g6(g6), .g7(g7), .g8(g8),
        .g_total(total_g)
    );
    
    always @(posedge clk) begin
        if (rst) begin
            spike_raw <= 1'b0;
            spike_delay <= 1'b0;
            spike <= 1'b0;
        end else begin
            
            if (total_g > 20'sd143) 
                spike_raw <= 1'b1;  
            else
                spike_raw <= 1'b0;

            spike_delay <= spike_raw;
            
            if (spike_raw == 1'b1 && spike_delay == 1'b0)
                spike <= 1'b1;
            else
                spike <= 1'b0;
        end
    end
    
endmodule
