`timescale 1ns / 1ps

module INb_Behave(
    input wire clk, rst,
    input wire signed [19:0] g1, g2, g3, g4, g5, g6, g7, g8,
    output reg spike,
    output reg signed [19:0] g_out
    );
    
wire signed [19:0] g_inb;
wire pf_spike_wire;
wire signed [19:0] g_out1,g_out2,g_out3,v_reg2;
parameter signed [19:0] g_sym = 20'sd164;

  INAND inb(
    .clk(clk),.rst(rst),
    .g1(g1),.g2(g2),.g3(g3),.g4(g4),.g5(g5),.g6(g6),.g7(g7),.g8(g8),
    .g_out(g_inb)
  );
  
   lifi neuron (
    .clk(clk), .rst(rst),
    .g_e(g_inb), 
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
        g_out=  g_out3;
        spike = pf_spike_wire;
      end    
endmodule
