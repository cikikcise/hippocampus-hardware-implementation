`timescale 1ns / 1ps

module `timescale 1ns / 1ps

module OBJ_Neuron(
    input  wire clk,
    input  wire rst,
    input wire signed [19:0] w0, w1, w2, w3, w4, w5, w6,w7,
    input wire signed [19:0] g0, g1, g2, g3, g4, g5, g6,g7,
    input wire signed [19:0] color_in, // renk girişi
    input wire signed [19:0] pf_input_i,
    output wire signed [19:0] g_out,
    output wire  pf_spike_lif
    );
    
    wire signed [19:0] g;
    wire signed [19:0] g_total_e;
    
    weight_mult OBJ_IN (
        .clk(clk), .rst(rst),
        .w0(w0),.w1(w1), .w2(w2),.w3(w3),.w4(w4),.w5(w5),.w6(w6),.w7(w7),
        .g0(g0), .g1(g1), .g2(g2), .g3(g3), .g4(g4), .g5(g5),.g6(g6),.g7(g7),
        .total_g(g)
    );
    
    assign g_total_e = g + color_in;
    
    lif_e OBJ(
        .clk(clk), .rst(rst),
        .g_out(g_out),
        .pf_spike_lif(pf_spike_lif),
        .pf_input_e(g_total_e),
        .pf_input_i(pf_input_i),
        .v_reg()
    );
    
      
    
endmodule
(
    input  wire clk,
    input  wire rst,
    input wire signed [19:0] w0, w1, w2, w3, w4, w5, w6,w7,
    input wire signed [19:0] g0, g1, g2, g3, g4, g5, g6,g7,
    input wire signed [19:0] color_in, // renk girişi
    input wire signed [19:0] pf_input_i,
    output wire signed [19:0] g_out,
    output wire  pf_spike_lif
    );
    
    wire signed [19:0] g;
    wire signed [19:0] g_total_e;
    
    weight_mult OBJ_IN (
        .clk(clk), .rst(rst),
        .w0(w0),.w1(w1), .w2(w2),.w3(w3),.w4(w4),.w5(w5),.w6(w6),.w7(w7),
        .g0(g0), .g1(g1), .g2(g2), .g3(g3), .g4(g4), .g5(g5),.g6(g6),.g7(g7),
        .total_g(g)
    );
    
    assign g_total_e = g + color_in;
    
    lif_e OBJ(
        .clk(clk), .rst(rst),
        .g_out(g_out),
        .pf_spike_lif(pf_spike_lif),
        .pf_input_e(g_total_e),
        .pf_input_i(pf_input_i),
        .v_reg()
    );
    
      
    
endmodule
