`timescale 1ns / 1ps
// Neuron Input Characteristics:
// - g_i (Inhibitory): Accumulates the input from the INN cell and neighboring PFI signals.
// - g_e (Excitatory): Takes the g_per and g_inp (color inputs) signals.
module lif_e(
    input  wire clk,
    input  wire rst,
    output reg [19:0]  g_out,  // Output
    output reg  pf_spike_lif,
    output reg [19:0] v_reg, // Neuron Potential
    input wire  [19:0] pf_input_e, // Summing of exc inputs
    input wire  [19:0] pf_input_i // Summing of inh inputs
    );
    
    wire pf_spike_wire;
    wire signed [19:0] g_out1,g_out2,g_out3,v_reg2;
    parameter signed [19:0] g_sym = 20'sd164;
    
     lif neuron (
      .clk(clk), .rst(rst),
      .g_e(pf_input_e), 
      .g_i(pf_input_i),             
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
        g_out =  g_out3;
        pf_spike_lif = pf_spike_wire;
        v_reg = v_reg2;
      end    
       
endmodule
