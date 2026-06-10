`timescale 1ns / 1ps
module INAND(
    input wire clk, rst,
    input wire signed [19:0] g1, g2, g3, g4, g5, g6, g7, g8,
    output reg signed [19:0] g_out
    );
    
    wire  signed [19:0] g_total;
    // Aggregates input conductances via an 8-input
    Adder_Tree_8in adder_inst (
        .clk(clk), .rst(rst),
        .g1(g1), .g2(g2), .g3(g3), .g4(g4),
        .g5(g5), .g6(g6), .g7(g7), .g8(g8),
        .g_total(g_total)
    );
    
  
    parameter signed [19:0] THRESHOLD = 20'sd985; // 30mS*8 
    parameter signed [19:0] OUT_VAL   = 20'sd164; // 40 mS
    
    reg firing;
    reg [3:0] counter;
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            firing <= 0;
            counter <= 0;
            g_out <= 0;
        end else begin
            // Firing control logic: Detects when total conductance exceeds threshold
            if (!firing) begin
                if (g_total >= THRESHOLD) begin
                    firing <= 1'b1;
                    counter <= 0;
                end
            end else begin
                if (counter >= 5) begin
                    firing <= 1'b0;
                    counter <= 0;
                end else begin
                    counter <= counter + 1;
                end
            end

            if (firing && counter >= 1 && counter <= 3)
                g_out <= OUT_VAL;
            else
                g_out <= 0;
        end
    end
endmodule
