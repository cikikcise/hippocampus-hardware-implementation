`timescale 1ns / 1ps

module IN_n(
    input  wire clk,
    input  wire rst,
    input  wire signed [19:0] g_per,
    output reg spike,
    output reg signed [19:0] g_cond
    );
    
    wire pf_spike_wire;
    wire signed [19:0] g_out1,g_out2,g_out3,v_reg2;
    parameter signed [19:0] g_sym = 20'sd164;
     lifi neuron (
      .clk(clk), .rst(rst),
      .g_e(g_per), 
      .g_i(20'sd0),             
      .spike_reg(pf_spike_wire),
      .v_reg(v_reg2) );
      
      conductance neuron_synp (
       .clk(clk),
       .rst(rst),
       .spike(pf_spike_wire),
       .g_out(g_out3),
       .g_sym(g_sym),
       .counter_out()
      );
      
       always @(*) begin
        g_cond =  g_out3;
        spike = pf_spike_wire;
      end    
    
endmodule
