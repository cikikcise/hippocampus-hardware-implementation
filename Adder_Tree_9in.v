`timescale 1ns / 1ps
/* -------------------------------------------------------------------------
 * SYNAPTIC INPUT ADDER TREE (Adder_Tree_9in)
 * -------------------------------------------------------------------------
 * This module performs a multi-stage pipelined summation of synaptic 
 * conductance inputs. It aggregates signals from 7 PFI neurons, the 
 * internal inhibitory (g_inn), and perception error (g_per) inputs.
 * ------------------------------------------------------------------------- */
module Adder_Tree_9in(
    input wire clk,
    input wire rst,
    input wire signed [19:0] g1, g2, g3, g4, g5, g6, g7, // PFI neuron inputs
    input wire signed [19:0] g_inn,                      // Internal inhibitory signal
    input wire signed [19:0] g_per,                      // Perception error
    output reg signed [19:0] g_total                     // CAONDUCTANCE OUTPUT
);

    // 1. Katman: 10 girişi 5 toplama indirir
    reg signed [20:0] s1_a, s1_b, s1_c, s1_d, s1_e;
    
    // 2. Katman: 5 girişi 3 toplama indirir (s1_e direkt geçer)
    reg signed [21:0] s2_a, s2_b, s2_e;
    
    // 3. Katman: 3 girişi 2 toplama indirir
    reg signed [22:0] s3_final;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            s1_a <= 0; s1_b <= 0; s1_c <= 0; s1_d <= 0; s1_e <= 0;
            s2_a <= 0; s2_b <= 0; s2_e <= 0;
            s3_final <= 0;
            g_total <= 0;
        end else begin
            // 1st Stage: Parallel summation of input pairs
            s1_a <= g1 + g2;
            s1_b <= g3 + g4;
            s1_c <= g5 + g6;
            s1_d <= g7;
            s1_e <= g_inn + g_per;

            s2_a <= s1_a + s1_b;
            s2_b <= s1_c + s1_d;
            s2_e <= s1_e; 

            // Final total summation
            s3_final <= s2_a + s2_b + s2_e;

            // Saturation logic to clamp values
            if (s3_final > 23'sd524287) 
                g_total <= 20'sd524287; // Max pozitif
            else if (s3_final < -23'sd524288) 
                g_total <= -20'sd524288; // Max negatif
            else 
                g_total <= s3_final[19:0];
        end
    end
endmodule
