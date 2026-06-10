`timescale 1ns / 1ps
/* -------------------------------------------------------------------------
 * LAYER 2: OBJECT NEURON PROCESSING AND STDP LEARNING MODULE
 * -------------------------------------------------------------------------
 * This module manages the object-level neurons (OBJ_Neurons) and implements 
 * Spike-Timing-Dependent Plasticity (STDP) for weight adaptation.
 * * - Memory Management: Handles internal weight RAM and weight matrix updates.
 * - STDP Learning: Executes weight updates triggered by pre- and post-synaptic 
 * spike events during training phases.
 * - Training Gate: Ensures weight updates occur only when external stimulus 
 * (color inputs) is present.
 * - Inference Mode: Provides a bypass for stimulus inputs to evaluate the 
 * network in a static state.
 * ------------------------------------------------------------------------- */
module layer2 (
    input  wire clk, rst,
    input  wire we,                   
    input  wire [5:0] w_addr,         
    input  wire signed [19:0] w_din,  
    
    input  wire signed [19:0] g_pfe1, g_pfe2, g_pfe3, g_pfe4, g_pfe5, g_pfe6, g_pfe7, g_pfe8,
    input  wire pfe_spike1, pfe_spike2, pfe_spike3, pfe_spike4, pfe_spike5, pfe_spike6, pfe_spike7, pfe_spike8,
    
    output wire signed [19:0] g_obj_out1, g_obj_out2, g_obj_out3, g_obj_out4, g_obj_out5, g_obj_out6, g_obj_out7, g_obj_out8,
    output wire OBJ_Spike1, OBJ_Spike2, OBJ_Spike3, OBJ_Spike4, OBJ_Spike5, OBJ_Spike6, OBJ_Spike7, OBJ_Spike8,
    input  wire [19:0] d_red, d_green, d_blue, d_black, d_white, d_yellow, d_pink, d_purple,
    input  wire [19:0] g_ina,
    output wire ready_out
);

    reg signed [19:0] weight_ram [0:63];
    initial $readmemh("C2_weights.mem", weight_ram);

    always @(posedge clk) begin
        if (we) weight_ram[w_addr] <= w_din;
    end

    reg signed [19:0] W [0:7][0:7];
    reg [5:0] read_addr;
    reg [5:0] write_addr_reg; 
    reg load_valid;            
    reg ready;
    
    wire internal_rst = rst || (!ready); 

    // SPIKE CAPTURE: Detects activity across pre- and post-synaptic layers
    wire [7:0] pre_spikes_in = {pfe_spike8, pfe_spike7, pfe_spike6, pfe_spike5, pfe_spike4, pfe_spike3, pfe_spike2, pfe_spike1};
    wire [7:0] post_spikes_in = {OBJ_Spike8, OBJ_Spike7, OBJ_Spike6, OBJ_Spike5, OBJ_Spike4, OBJ_Spike3, OBJ_Spike2, OBJ_Spike1};

    wire any_pre_fired = |pre_spikes_in;
    wire any_post_fired = |post_spikes_in;

    reg [2:0] active_pre_idx;
    always @(*) begin
        if      (pre_spikes_in[0]) active_pre_idx = 3'd0;
        else if (pre_spikes_in[1]) active_pre_idx = 3'd1;
        else if (pre_spikes_in[2]) active_pre_idx = 3'd2;
        else if (pre_spikes_in[3]) active_pre_idx = 3'd3;
        else if (pre_spikes_in[4]) active_pre_idx = 3'd4;
        else if (pre_spikes_in[5]) active_pre_idx = 3'd5;
        else if (pre_spikes_in[6]) active_pre_idx = 3'd6;
        else if (pre_spikes_in[7]) active_pre_idx = 3'd7;
        else active_pre_idx = 3'd0;
    end

    reg [2:0] active_post_idx;
    always @(*) begin
        if      (post_spikes_in[0]) active_post_idx = 3'd0;
        else if (post_spikes_in[1]) active_post_idx = 3'd1;
        else if (post_spikes_in[2]) active_post_idx = 3'd2;
        else if (post_spikes_in[3]) active_post_idx = 3'd3;
        else if (post_spikes_in[4]) active_post_idx = 3'd4;
        else if (post_spikes_in[5]) active_post_idx = 3'd5;
        else if (post_spikes_in[6]) active_post_idx = 3'd6;
        else if (post_spikes_in[7]) active_post_idx = 3'd7;
        else active_post_idx = 3'd0;
    end

   // TRAINING GATE: Weight updates are enabled only during the training phase 
    // when external stimulus (color inputs) is active.
    wire is_training = (d_red != 0) || (d_green != 0) || (d_blue != 0) || (d_black != 0) || 
                       (d_white != 0) || (d_yellow != 0) || (d_pink != 0) || (d_purple != 0);

    wire stdp_done;
    wire learn_done;
    
    // RAM'e yazma işlemi yapılırken '1' olan meşguliyet bayrağı
    reg is_writing; 
    always @(posedge clk) begin
        if (internal_rst) is_writing <= 1'b0;
        // Sadece eğitim anındaysa ve STDP bittiyse yazmayı başlat (kilitle)
        else if (stdp_done && is_training) is_writing <= 1'b1; 
        else if (learn_done) is_writing <= 1'b0; // Yazma bitince aç
    end

    reg [2:0] target_post_reg;
    reg [2:0] target_pre_reg;

    always @(posedge clk) begin
        if (internal_rst) begin
            target_post_reg <= 3'd0;
            target_pre_reg  <= 3'd0;
        end 
        else if (!is_writing) begin
            if (any_post_fired) target_post_reg <= active_post_idx;
            if (any_pre_fired)  target_pre_reg  <= active_pre_idx;
        end
    end

    wire signed [19:0] w_diff;

    // STDP Modülü
    stdp stdp_inst (
        .clk(clk),
        .rst(internal_rst),
        .pre_spike(any_pre_fired),
        .post_spike(any_post_fired),
        .delta_w(w_diff),
        .done(stdp_done), 
        .current_count1(), .current_count2(), .exp_in_out(), .exp_out_out()
    );

    wire signed [19:0] final_w;

    // RAM GÜNCELLEYİCİ
    learn_top #(
        .DATA_WIDTH(20), 
        .ADDR_WIDTH(6), 
        .MEM_FILE("C2_weights.mem")
    ) ram_updater (
        .clk(clk), 
        .rst(internal_rst), 
        
        // MUHTEŞEM KİLİT BURASI: 
        // STDP done üretse bile, dışarıdan renk verilmiyorsa (boşluktaysak) BRAM GÜNCELLENMEZ!
        .update_req(stdp_done && is_training),        
        
        .delta_w_in(w_diff),            
        .neuron_addr({target_post_reg, target_pre_reg}), 
        .final_weight_out(final_w), 
        .done2(learn_done)              
    );

    // =========================================================================
    // MATRİS GÜNCELLEME
    // =========================================================================
    always @(posedge clk) begin
        if (rst) begin
            read_addr <= 0; write_addr_reg <= 0; load_valid <= 0; ready <= 0;
        end 
        else if (!ready) begin
            read_addr <= read_addr + 1; write_addr_reg <= read_addr; load_valid <= 1;
            
            if (load_valid) begin
                W[write_addr_reg[5:3]][write_addr_reg[2:0]] <= weight_ram[write_addr_reg];
            end
            
            if (write_addr_reg == 6'd63 && load_valid) begin
                ready <= 1'b1;
            end
        end 
        else if (learn_done && ready) begin
            W[target_post_reg][target_pre_reg] <= final_w;
            
            $display("=======================================================");
            $display("[%t] >>> LAYER 2 BRAM & MATRIS GUNCELLEMESI TAMAMLANDI! <<<", $time);
            $display("    Nöron Adres   : Pre %d -> Post %d", target_pre_reg, target_post_reg);
            $display("    Uretilen Delta: %d", w_diff);
            $display("    YENI AGIRLIK  : %d", final_w);
            $display("=======================================================\n");
        end
    end

    reg ready_d1; always @(posedge clk) ready_d1 <= ready;
    always @(posedge clk) if (ready && !ready_d1) $display("[%t] LAYER_2_LOG: Agirliklar yueklendi, ready = 1", $time);
    assign ready_out = ready;

   // INFERENCE MODE SWITCH: Disables stimulus inputs to allow testing 
    // without triggering weight updates or cascading into previous layers.
    reg inference_mode = 1'b0; 
    
    wire signed [19:0] c_red    = inference_mode ? 20'sd0 : d_red;
    wire signed [19:0] c_green  = inference_mode ? 20'sd0 : d_green;
    wire signed [19:0] c_blue   = inference_mode ? 20'sd0 : d_blue;
    wire signed [19:0] c_black  = inference_mode ? 20'sd0 : d_black;
    wire signed [19:0] c_white  = inference_mode ? 20'sd0 : d_white;
    wire signed [19:0] c_yellow = inference_mode ? 20'sd0 : d_yellow;
    wire signed [19:0] c_pink   = inference_mode ? 20'sd0 : d_pink;
    wire signed [19:0] c_purple = inference_mode ? 20'sd0 : d_purple;

    
    OBJ_Neuron OBJ_1 (.clk(clk), .rst(internal_rst), .w0(W[0][0]), .w1(W[0][1]), .w2(W[0][2]), .w3(W[0][3]), .w4(W[0][4]), .w5(W[0][5]), .w6(W[0][6]), .w7(W[0][7]), .g0(g_pfe1), .g1(g_pfe2), .g2(g_pfe3), .g3(g_pfe4), .g4(g_pfe5), .g5(g_pfe6), .g6(g_pfe7), .g7(g_pfe8), .color_in(c_red),    .pf_input_i(g_ina), .g_out(g_obj_out1), .pf_spike_lif(OBJ_Spike1));
    OBJ_Neuron OBJ_2 (.clk(clk), .rst(internal_rst), .w0(W[1][0]), .w1(W[1][1]), .w2(W[1][2]), .w3(W[1][3]), .w4(W[1][4]), .w5(W[1][5]), .w6(W[1][6]), .w7(W[1][7]), .g0(g_pfe1), .g1(g_pfe2), .g2(g_pfe3), .g3(g_pfe4), .g4(g_pfe5), .g5(g_pfe6), .g6(g_pfe7), .g7(g_pfe8), .color_in(c_green),  .pf_input_i(g_ina), .g_out(g_obj_out2), .pf_spike_lif(OBJ_Spike2));
    OBJ_Neuron OBJ_3 (.clk(clk), .rst(internal_rst), .w0(W[2][0]), .w1(W[2][1]), .w2(W[2][2]), .w3(W[2][3]), .w4(W[2][4]), .w5(W[2][5]), .w6(W[2][6]), .w7(W[2][7]), .g0(g_pfe1), .g1(g_pfe2), .g2(g_pfe3), .g3(g_pfe4), .g4(g_pfe5), .g5(g_pfe6), .g6(g_pfe7), .g7(g_pfe8), .color_in(c_blue),   .pf_input_i(g_ina), .g_out(g_obj_out3), .pf_spike_lif(OBJ_Spike3));
    OBJ_Neuron OBJ_4 (.clk(clk), .rst(internal_rst), .w0(W[3][0]), .w1(W[3][1]), .w2(W[3][2]), .w3(W[3][3]), .w4(W[3][4]), .w5(W[3][5]), .w6(W[3][6]), .w7(W[3][7]), .g0(g_pfe1), .g1(g_pfe2), .g2(g_pfe3), .g3(g_pfe4), .g4(g_pfe5), .g5(g_pfe6), .g6(g_pfe7), .g7(g_pfe8), .color_in(c_black),  .pf_input_i(g_ina), .g_out(g_obj_out4), .pf_spike_lif(OBJ_Spike4));
    OBJ_Neuron OBJ_5 (.clk(clk), .rst(internal_rst), .w0(W[4][0]), .w1(W[4][1]), .w2(W[4][2]), .w3(W[4][3]), .w4(W[4][4]), .w5(W[4][5]), .w6(W[4][6]), .w7(W[4][7]), .g0(g_pfe1), .g1(g_pfe2), .g2(g_pfe3), .g3(g_pfe4), .g4(g_pfe5), .g5(g_pfe6), .g6(g_pfe7), .g7(g_pfe8), .color_in(c_white),  .pf_input_i(g_ina), .g_out(g_obj_out5), .pf_spike_lif(OBJ_Spike5));
    OBJ_Neuron OBJ_6 (.clk(clk), .rst(internal_rst), .w0(W[5][0]), .w1(W[5][1]), .w2(W[5][2]), .w3(W[5][3]), .w4(W[5][4]), .w5(W[5][5]), .w6(W[5][6]), .w7(W[5][7]), .g0(g_pfe1), .g1(g_pfe2), .g2(g_pfe3), .g3(g_pfe4), .g4(g_pfe5), .g5(g_pfe6), .g6(g_pfe7), .g7(g_pfe8), .color_in(c_yellow), .pf_input_i(g_ina), .g_out(g_obj_out6), .pf_spike_lif(OBJ_Spike6));
    OBJ_Neuron OBJ_7 (.clk(clk), .rst(internal_rst), .w0(W[6][0]), .w1(W[6][1]), .w2(W[6][2]), .w3(W[6][3]), .w4(W[6][4]), .w5(W[6][5]), .w6(W[6][6]), .w7(W[6][7]), .g0(g_pfe1), .g1(g_pfe2), .g2(g_pfe3), .g3(g_pfe4), .g4(g_pfe5), .g5(g_pfe6), .g6(g_pfe7), .g7(g_pfe8), .color_in(c_pink),   .pf_input_i(g_ina), .g_out(g_obj_out7), .pf_spike_lif(OBJ_Spike7));
    OBJ_Neuron OBJ_8 (.clk(clk), .rst(internal_rst), .w0(W[7][0]), .w1(W[7][1]), .w2(W[7][2]), .w3(W[7][3]), .w4(W[7][4]), .w5(W[7][5]), .w6(W[7][6]), .w7(W[7][7]), .g0(g_pfe1), .g1(g_pfe2), .g2(g_pfe3), .g3(g_pfe4), .g4(g_pfe5), .g5(g_pfe6), .g6(g_pfe7), .g7(g_pfe8), .color_in(c_purple), .pf_input_i(g_ina), .g_out(g_obj_out8), .pf_spike_lif(OBJ_Spike8));

endmodule
