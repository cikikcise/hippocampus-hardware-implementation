`timescale 1ns / 1ps

module layer1(
    input  wire clk,
    input  wire rst,
    
    // Outputs of Conudctance
    output wire signed [19:0] g_out1, g_out2, g_out3, g_out4, g_out5, g_out6, g_out7, g_out8, v_reg, 
    output wire signed [19:0] gi_out1, gi_out2, gi_out3, gi_out4, gi_out5, gi_out6, gi_out7, gi_out8, 
    
    // Output of Spike
    output wire pf_spike_lif1, pf_spike_lif2, pf_spike_lif3, pf_spike_lif4, pf_spike_lif5, pf_spike_lif6, pf_spike_lif7, pf_spike_lif8, 
    output wire pfi_spike_lif1, pfi_spike_lif2, pfi_spike_lif3, pfi_spike_lif4, pfi_spike_lif5, pfi_spike_lif6, pfi_spike_lif7, pfi_spike_lif8, 
    
    // Inputs 
    input wire signed [19:0] g_red, g_green, g_blue, g_black, g_white, g_yellow, g_pink, g_purple,
    input wire signed [19:0] g_inn, g_per
);

    
    wire signed [19:0] gi1, gi2, gi3, gi4, gi5, gi6, gi7, gi8;
    wire signed [19:0] in_e1, in_e2, in_e3, in_e4, in_e5, in_e6, in_e7, in_e8;

    // Aggregate of Inputs
    assign in_e1 = g_per + g_red;
    assign in_e2 = g_per + g_green;
    assign in_e3 = g_per + g_blue;
    assign in_e4 = g_per + g_black;
    assign in_e5 = g_per + g_white;
    assign in_e6 = g_per + g_yellow;
    assign in_e7 = g_per + g_pink;
    assign in_e8 = g_per + g_purple;

    // aggregation of each inputs
    Adder_Tree_9in PFE1_AT (.clk(clk),.rst(rst), .g1(gi_out2),.g2(gi_out3),.g3(gi_out4),.g4(gi_out5),.g5(gi_out6),.g6(gi_out7),.g7(gi_out8),.g_inn(g_inn),.g_per(20'sd0),.g_total(gi1));
    Adder_Tree_9in PFE2_AT (.clk(clk),.rst(rst), .g1(gi_out1),.g2(gi_out3),.g3(gi_out4),.g4(gi_out5),.g5(gi_out6),.g6(gi_out7),.g7(gi_out8),.g_inn(g_inn),.g_per(20'sd0),.g_total(gi2));
    Adder_Tree_9in PFE3_AT (.clk(clk),.rst(rst), .g1(gi_out1),.g2(gi_out2),.g3(gi_out4),.g4(gi_out5),.g5(gi_out6),.g6(gi_out7),.g7(gi_out8),.g_inn(g_inn),.g_per(20'sd0),.g_total(gi3));
    Adder_Tree_9in PFE4_AT (.clk(clk),.rst(rst), .g1(gi_out1),.g2(gi_out2),.g3(gi_out3),.g4(gi_out7),.g5(gi_out5),.g6(gi_out6),.g7(gi_out8),.g_inn(g_inn),.g_per(20'sd0),.g_total(gi4));
    Adder_Tree_9in PFE5_AT (.clk(clk),.rst(rst), .g1(gi_out1),.g2(gi_out2),.g3(gi_out3),.g4(gi_out4),.g5(gi_out6),.g6(gi_out7),.g7(gi_out8),.g_inn(g_inn),.g_per(20'sd0),.g_total(gi5));
    Adder_Tree_9in PFE6_AT (.clk(clk),.rst(rst), .g1(gi_out1),.g2(gi_out2),.g3(gi_out3),.g4(gi_out4),.g5(gi_out5),.g6(gi_out7),.g7(gi_out8),.g_inn(g_inn),.g_per(20'sd0),.g_total(gi6));
    Adder_Tree_9in PFE7_AT (.clk(clk),.rst(rst), .g1(gi_out1),.g2(gi_out2),.g3(gi_out3),.g4(gi_out4),.g5(gi_out5),.g6(gi_out6),.g7(gi_out8),.g_inn(g_inn),.g_per(20'sd0),.g_total(gi7));
    Adder_Tree_9in PFE8_AT (.clk(clk),.rst(rst), .g1(gi_out1),.g2(gi_out2),.g3(gi_out3),.g4(gi_out4),.g5(gi_out5),.g6(gi_out6),.g7(gi_out7),.g_inn(g_inn),.g_per(20'sd0),.g_total(gi8));

    // --- Nöronlar ---
    lif_e pfe1(.clk(clk), .rst(rst), .g_out(g_out1), .pf_spike_lif(pf_spike_lif1), .pf_input_e(in_e1), .pf_input_i(gi1), .v_reg(v_reg));
    lif_in pfi1(.clk(clk), .rst(rst), .g_out(gi_out1), .pf_spike_lif(pfi_spike_lif1), .pf_input_e(g_out1), .pf_input_i(20'sd0));
    
    lif_e pfe2(.clk(clk), .rst(rst), .g_out(g_out2), .pf_spike_lif(pf_spike_lif2), .pf_input_e(in_e2), .pf_input_i(gi2));
    lif_in pfi2(.clk(clk), .rst(rst), .g_out(gi_out2), .pf_spike_lif(pfi_spike_lif2), .pf_input_e(g_out2), .pf_input_i(20'sd0));

    lif_e pfe3(.clk(clk), .rst(rst), .g_out(g_out3), .pf_spike_lif(pf_spike_lif3), .pf_input_e(in_e3), .pf_input_i(gi3));
    lif_in pfi3(.clk(clk), .rst(rst), .g_out(gi_out3), .pf_spike_lif(pfi_spike_lif3), .pf_input_e(g_out3), .pf_input_i(20'sd0));

    lif_e pfe4(.clk(clk), .rst(rst), .g_out(g_out4), .pf_spike_lif(pf_spike_lif4), .pf_input_e(in_e4), .pf_input_i(gi4));
    lif_in pfi4(.clk(clk), .rst(rst), .g_out(gi_out4), .pf_spike_lif(pfi_spike_lif4), .pf_input_e(g_out4), .pf_input_i(20'sd0));

    lif_e pfe5(.clk(clk), .rst(rst), .g_out(g_out5), .pf_spike_lif(pf_spike_lif5), .pf_input_e(in_e5), .pf_input_i(gi5));
    lif_in pfi5(.clk(clk), .rst(rst), .g_out(gi_out5), .pf_spike_lif(pfi_spike_lif5), .pf_input_e(g_out5), .pf_input_i(20'sd0));

    lif_e pfe6(.clk(clk), .rst(rst), .g_out(g_out6), .pf_spike_lif(pf_spike_lif6), .pf_input_e(in_e6), .pf_input_i(gi6));
    lif_in pfi6(.clk(clk), .rst(rst), .g_out(gi_out6), .pf_spike_lif(pfi_spike_lif6), .pf_input_e(g_out6), .pf_input_i(20'sd0));

    lif_e pfe7(.clk(clk), .rst(rst), .g_out(g_out7), .pf_spike_lif(pf_spike_lif7), .pf_input_e(in_e7), .pf_input_i(gi7));
    lif_in pfi7(.clk(clk), .rst(rst), .g_out(gi_out7), .pf_spike_lif(pfi_spike_lif7), .pf_input_e(g_out7), .pf_input_i(20'sd0));

    lif_e pfe8(.clk(clk), .rst(rst), .g_out(g_out8), .pf_spike_lif(pf_spike_lif8), .pf_input_e(in_e8), .pf_input_i(gi8));
    lif_in pfi8(.clk(clk), .rst(rst), .g_out(gi_out8), .pf_spike_lif(pfi_spike_lif8), .pf_input_e(g_out8), .pf_input_i(20'sd0));

endmodule
