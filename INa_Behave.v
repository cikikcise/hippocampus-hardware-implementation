`timescale 1ns / 1ps
module INa_Behave(
    input wire clk, rst,
    input wire signed [19:0] g1, g2, g3, g4, g5, g6, g7, g8, // Girişler 20-bit
    input wire signed [19:0] inb_g, inn_g,
    output wire spike,
    output wire signed [19:0] g_out
);

    wire spike1;
    wire signed [19:0] gi_total;
    wire pf_spike_wire; // İsim hatasını düzelttim
    wire signed [19:0] g_out_syn, g_out_syn1;
    parameter signed [19:0] g_sym1 = 20'sd328;
    parameter signed [19:0] g_sym = 20'sd164;

    INOR ina_or_gate (
        .g1(g1), .g2(g2), .g3(g3), .g4(g4),
        .g5(g5), .g6(g6), .g7(g7), .g8(g8),
        .spike(spike1),
        .clk(clk), .rst(rst)
    );
    
    assign gi_total = inb_g + inn_g;
    
    conductance neuron_synp_ara (
        .clk(clk),
        .rst(rst),
        .spike(spike1),
        .g_out(g_out_syn1),
        .g_sym(g_sym),
        .counter_out()
    );

    lifi neuron (
        .clk(clk), .rst(rst),
        .g_e(g_out_syn1), 
        .g_i(gi_total),              
        .spike_reg(pf_spike_wire),
        .v_reg()
    );
      
    conductance neuron_synp (
        .clk(clk),
        .rst(rst),
        .spike(pf_spike_wire),
        .g_out(g_out_syn),
        .g_sym(g_sym1),
        .counter_out()
    );
      
    assign g_out = g_out_syn;
    assign spike = pf_spike_wire;

endmodule
