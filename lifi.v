`timescale 1ns / 1ps
    module lifi(
    input  wire                 clk,
    input  wire                 rst,

    input  wire signed [19:0]   g_e,   // Q7.12
    input  wire signed [19:0]   g_i,   // Q7.12

    output reg                  spike_reg,
    output reg signed [19:0]    v_reg  // Q8.12
);

    // --------------------------------------------------
    // PARAMETRELER (Q8.12)
    // --------------------------------------------------
    parameter signed [19:0] V_TH         = -20'sd163840; // -40 mV
    parameter signed [19:0] V_RESET      = -20'sd184320; // -45 mV
    parameter signed [19:0] E_EXCITATORY =  20'sd0;      //   0 mV
    parameter signed [19:0] E_INHIBITORY = -20'sd245760; // -70 mV
    parameter signed [19:0] E_LEAK       = V_RESET;

    // Q0.12
    parameter signed [19:0] dt_tau = 20'sd103;//410; // dt/tau dt = 1ms tau = 10 ms

    // Q7.12
    parameter signed [19:0] R_mem  = 20'sd81920; // 20 olarak aldım

    parameter [19:0] REFRACTORY_CLOCKS = 20'd4600; // 1ms

    // --------------------------------------------------
    // INTERNAL SIGNALS
    // --------------------------------------------------
    wire signed [19:0] df_e, df_i;

    wire signed [39:0] i_e_big, i_i_big;
    wire signed [40:0] i_total_big;
    wire signed [28:0] i_total;

    wire signed [48:0] syn_big;
    wire signed [28:0] syn_term;

    wire signed [19:0] leak_term;
    wire signed [28:0] dv_dt_term;

    wire signed [48:0] dv_big;
    wire signed [19:0] dv;

    wire signed [20:0] v_next_ext;
    wire signed [19:0] v_next_sat;

    reg  [19:0] refractory_counter;

    // --------------------------------------------------
    // LIF EQUATION
    // dv/dt = (E_L - v)
    //       + g_e (E_e - v)
    //       + g_i (E_i - v)
    // --------------------------------------------------

    // Driving forces
    assign df_e =  E_EXCITATORY - v_reg  ;
    assign df_i = E_INHIBITORY - v_reg;

    // Synaptic currents
    assign i_e_big = g_e * df_e;
    assign i_i_big = g_i * df_i;

    // Excitatory
    wire signed [48:0] syn_exc_big;
    wire signed [28:0] syn_exc;

    // Inhibitory
    wire signed [48:0] syn_inh_big;
    wire signed [28:0] syn_inh;

    assign syn_exc_big = R_mem * (i_e_big >>> 12);
    assign syn_exc     = syn_exc_big >>> 12;

    assign syn_inh_big = R_mem * (i_i_big >>> 12);
    assign syn_inh     = syn_inh_big >>> 12; // 24
    
    // Leak
    assign leak_term = E_LEAK - v_reg;
    
    // TOTAL dv/dt
    assign dv_dt_term = leak_term + syn_exc + syn_inh;

    // Euler integration
    assign dv_big = dt_tau * dv_dt_term;
    assign dv     = dv_big >>> 12; //24

    // --------------------------------------------------
    // SATURATION 
    // --------------------------------------------------
    assign v_next_ext = v_reg + dv;

    assign v_next_sat =
        (v_next_ext > V_TH)         ? V_TH :
        (v_next_ext < E_INHIBITORY) ? E_INHIBITORY :
                                      v_next_ext[19:0];


    always @(posedge clk or posedge rst) begin
        if (rst) begin
            v_reg <= E_LEAK;
            spike_reg <= 1'b0;
            refractory_counter <= 0;
        end else begin
            if (refractory_counter > 0) begin
                refractory_counter <= refractory_counter - 1;
                v_reg <= V_RESET;
                spike_reg <= 1'b0;
            end else begin
                spike_reg <= 1'b0;
                if (v_reg >= V_TH) begin
                    v_reg <= V_RESET;
                    spike_reg <= 1'b1;
                    refractory_counter <= REFRACTORY_CLOCKS;
                end else begin
                    v_reg <= v_next_sat;
                end
            end
        end
    end

endmodule
