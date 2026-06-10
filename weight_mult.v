/* -------------------------------------------------------------------------
 * MULTIPLY-ACCUMULATE (MAC) UNIT FOR SYNAPTIC WEIGHTING (weight_mult)
 * -------------------------------------------------------------------------
 * This module implements a time-multiplexed Multiply-Accumulate (MAC) unit 
 * to perform synaptic weight multiplication.
 * - Resource Efficiency: Uses a single DSP-optimized path by time-sharing 
 * resources over 8 clock cycles to compute the weighted sum.
 * - Precision: Employs a 40-bit accumulator to prevent precision loss during 
 * summation before scaling back to the standard Q3.16 format.
 * - Data Alignment: Normalizes the product using an arithmetic shift (>>12) 
 * to align with the fixed-point representation.
 * ------------------------------------------------------------------------- */
`timescale 1ns / 1ps
module weight_mult(
    input wire clk, rst,
    input wire signed [19:0] w0, w1, w2, w3, w4, w5, w6, w7, // Synaptic weights
    input wire signed [19:0] g0, g1, g2, g3, g4, g5, g6, g7, // Conductance inputs
    output reg signed [19:0] total_g                         // Weighted sum output
    );

    reg [2:0] count;              // Multiplexer selection counter (0-7)
    reg signed [19:0] sel_w, sel_g; 
    reg signed [39:0] acc;        // 40-bit accumulator to ensure numerical precision

    // MUX: Sequentially selects weight-conductance pairs for MAC processing
    always @(*) begin
        case(count)
            3'd0: begin sel_w = w0; sel_g = g0; end
            3'd1: begin sel_w = w1; sel_g = g1; end
            3'd2: begin sel_w = w2; sel_g = g2; end
            3'd3: begin sel_w = w3; sel_g = g3; end
            3'd4: begin sel_w = w4; sel_g = g4; end
            3'd5: begin sel_w = w5; sel_g = g5; end
            3'd6: begin sel_w = w6; sel_g = g6; end
            3'd7: begin sel_w = w7; sel_g = g7; end
            default: begin sel_w = 20'sd0; sel_g = 20'sd0; end
        endcase
    end

    // MAC OPERATION: Sequential multiply-accumulate logic
    always @(posedge clk) begin
        if (rst) begin
            count <= 3'd0;
            acc <= 40'sd0;
            total_g <= 20'sd0;
        end else begin
            // Accumulate products
            acc <= acc + (sel_w * sel_g);
            
            if (count == 3'd7) begin
                count <= 3'd0;
                // Final scaling operation: Normalizing the result back to Q-format
                total_g <= (acc + (sel_w * sel_g)) >>> 12; 
                acc <= 40'sd0; // Reset accumulator for next cycle
            end else begin
                count <= count + 1;
            end
        end
    end
endmodule
