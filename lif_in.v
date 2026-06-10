`timescale 1ns / 1ps
/* -------------------------------------------------------------------------
 * INHIBITORY NEURON MODULE (lif_in)
 * ------------------------------------------------------------------------- */
module lif_in(
    input  wire clk,
    input  wire rst,
    output reg [19:0]  g_out,        // Conductance for inhibitory 
    output reg         pf_spike_lif, // Spike flag of the inhibitory neuron
    output reg [19:0]  v_reg,        // Membrane potential of the LIF model
    input wire  [19:0] pf_input_e,   //  excitatory synaptic input
    input wire  [19:0] pf_input_i    //  inhibitory synaptic input
);
    
    wire pf_spike_wire;
    wire signed [19:0] g_out1,g_out2,g_out3,v_reg2;
    parameter signed [19:0] g_sym = 20'sd328;

      
    lifi neuron (
      .clk(clk), .rst(rst),
      .g_e(pf_input_e), 
      .g_i(pf_input_i),             
      .spike_reg(pf_spike_wire),
      .v_reg(v_reg2)
    );
        
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
