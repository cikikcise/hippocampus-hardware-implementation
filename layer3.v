`timescale 1ns / 1ps

module layer3 (
    input  wire clk, rst,
    output wire ready_out,
    input  wire we,                    
    input  wire [7:0] w_addr,          
    input  wire signed [19:0] w_din,  
    input  wire signed [19:0] g_obj1, g_obj2, g_obj3, g_obj4, g_obj5, g_obj6, g_obj7, g_obj8,
    input  wire OBJ_Spike1, OBJ_Spike2, OBJ_Spike3, OBJ_Spike4, OBJ_Spike5, OBJ_Spike6, OBJ_Spike7, OBJ_Spike8,
    input  wire [19:0] g_inb, g_inc,
    input  wire signed [19:0] g_dir1, g_dir2, g_dir3, g_dir4, g_dir5, g_dir6, 
                              g_dir7, g_dir8, g_dir9, g_dir10, g_dir11, g_dir12,
                              g_dir13, g_dir14, g_dir15, g_dir16, g_dir17, g_dir18,
    output wire signed [19:0] g_HDPC1, g_HDPC2, g_HDPC3, g_HDPC4, g_HDPC5, g_HDPC6, g_HDPC7, g_HDPC8, g_HDPC9, g_HDPC10, g_HDPC11, g_HDPC12, g_HDPC13, g_HDPC14, g_HDPC15, g_HDPC16, g_HDPC17, g_HDPC18,
    output wire HDPC_Spike1, HDPC_Spike2, HDPC_Spike3, HDPC_Spike4, HDPC_Spike5, HDPC_Spike6, HDPC_Spike7, HDPC_Spike8, HDPC_Spike9, HDPC_Spike10, HDPC_Spike11, HDPC_Spike12, HDPC_Spike13, HDPC_Spike14, HDPC_Spike15, HDPC_Spike16, HDPC_Spike17, HDPC_Spike18
);

    reg signed [19:0] weight_ram [0:143];
    initial $readmemh("C3_weights.mem", weight_ram);
    
    always @(posedge clk) if (we) weight_ram[w_addr] <= w_din;

    reg signed [19:0] W [0:17][0:7];
    reg [7:0] read_addr; reg [7:0] write_addr_reg; reg load_valid; reg ready;
    wire internal_rst = rst || (!ready);

    wire [7:0] pre_spikes_in = {OBJ_Spike8, OBJ_Spike7, OBJ_Spike6, OBJ_Spike5, OBJ_Spike4, OBJ_Spike3, OBJ_Spike2, OBJ_Spike1};
    wire [17:0] post_spikes_in = {HDPC_Spike18, HDPC_Spike17, HDPC_Spike16, HDPC_Spike15, HDPC_Spike14, HDPC_Spike13, HDPC_Spike12, HDPC_Spike11, HDPC_Spike10, HDPC_Spike9, HDPC_Spike8, HDPC_Spike7, HDPC_Spike6, HDPC_Spike5, HDPC_Spike4, HDPC_Spike3, HDPC_Spike2, HDPC_Spike1};
    
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

    reg [4:0] active_post_idx;
    always @(*) begin
        if      (post_spikes_in[0])  active_post_idx = 5'd0;
        else if (post_spikes_in[1])  active_post_idx = 5'd1;
        else if (post_spikes_in[2])  active_post_idx = 5'd2;
        else if (post_spikes_in[3])  active_post_idx = 5'd3;
        else if (post_spikes_in[4])  active_post_idx = 5'd4;
        else if (post_spikes_in[5])  active_post_idx = 5'd5;
        else if (post_spikes_in[6])  active_post_idx = 5'd6;
        else if (post_spikes_in[7])  active_post_idx = 5'd7;
        else if (post_spikes_in[8])  active_post_idx = 5'd8;
        else if (post_spikes_in[9])  active_post_idx = 5'd9;
        else if (post_spikes_in[10]) active_post_idx = 5'd10;
        else if (post_spikes_in[11]) active_post_idx = 5'd11;
        else if (post_spikes_in[12]) active_post_idx = 5'd12;
        else if (post_spikes_in[13]) active_post_idx = 5'd13;
        else if (post_spikes_in[14]) active_post_idx = 5'd14;
        else if (post_spikes_in[15]) active_post_idx = 5'd15;
        else if (post_spikes_in[16]) active_post_idx = 5'd16;
        else if (post_spikes_in[17]) active_post_idx = 5'd17;
        else active_post_idx = 5'd0;
    end

    reg [2:0] last_pre_addr = 3'd0;
    reg [4:0] last_post_addr = 5'd0;

    always @(posedge clk) begin
        if (internal_rst) begin
            last_pre_addr <= 3'd0;
            last_post_addr <= 5'd0;
        end else begin
            if (any_pre_fired) last_pre_addr <= active_pre_idx;
            if (any_post_fired) last_post_addr <= active_post_idx;
        end
    end

    wire [4:0] target_post = any_post_fired ? active_post_idx : last_post_addr;
    wire [2:0] target_pre  = any_pre_fired ? active_pre_idx : last_pre_addr;

    wire stdp_done;
    wire signed [19:0] w_diff;

    stdp stdp_inst (
        .clk(clk),
        .rst(internal_rst),
        .pre_spike(any_pre_fired),
        .post_spike(any_post_fired),
        .delta_w(w_diff),
        .done(stdp_done), 
        .current_count1(), .current_count2(), .exp_in_out(), .exp_out_out()
    );

    wire learn_done;
    wire signed [19:0] final_w;

    learn_top #(
        .DATA_WIDTH(20), 
        .ADDR_WIDTH(8), 
        .MEM_FILE("C3_weights.mem")
    ) ram_updater (
        .clk(clk), 
        .rst(internal_rst), 
        .update_req(stdp_done),        
        .delta_w_in(w_diff),           
        .neuron_addr({target_post, target_pre}), 
        .final_weight_out(final_w), 
        .done2(learn_done)             
    );

    // =========================================================================
    // MULTIPLE DRIVER HATASINI ÇÖZEN TEK PARÇA ALWAYS BLOĞU
    // =========================================================================
    always @(posedge clk) begin
        if (rst) begin
            read_addr <= 0; write_addr_reg <= 0; load_valid <= 0; ready <= 0;
        end 
        else if (!ready) begin
            // İlk Yükleme
            read_addr <= read_addr + 1; write_addr_reg <= read_addr; load_valid <= 1;
            if (load_valid) W[write_addr_reg / 8][write_addr_reg % 8] <= weight_ram[write_addr_reg];
            if (write_addr_reg == 8'd143 && load_valid) ready <= 1'b1;
        end 
        else if (learn_done && ready) begin
            // STDP Sonrası Güncelleme
            W[target_post][target_pre] <= final_w;
            
            $display("=======================================================");
            $display("[%t] >>> LAYER 3 BRAM & MATRIS GUNCELLEMESI TAMAMLANDI! <<<", $time);
            $display("    Nöron Adres   : Pre %d -> Post %d", target_pre, target_post);
            $display("    Uretilen Delta: %d", w_diff);
            $display("    YENI AGIRLIK  : %d", final_w);
            $display("=======================================================\n");
        end
    end

    reg ready_d1; always @(posedge clk) ready_d1 <= ready;
    always @(posedge clk) if (ready && !ready_d1) $display("[%t] LAYER_3_LOG: Agirliklar yueklendi, ready = 1", $time);
    assign ready_out = ready;

    // NÖRONLAR
    wire signed [19:0] g_in = g_inb + g_inc;
    OBJ_Neuron HDPC1  (.clk(clk), .rst(internal_rst), .w0(W[0][0]),  .w1(W[0][1]),  .w2(W[0][2]),  .w3(W[0][3]),  .w4(W[0][4]),  .w5(W[0][5]),  .w6(W[0][6]),  .w7(W[0][7]),  .g0(g_obj1), .g1(g_obj2), .g2(g_obj3), .g3(g_obj4), .g4(g_obj5), .g5(g_obj6), .g6(g_obj7), .g7(g_obj8), .color_in(g_dir1),  .pf_input_i(g_in), .g_out(g_HDPC1),  .pf_spike_lif(HDPC_Spike1));
    OBJ_Neuron HDPC2  (.clk(clk), .rst(internal_rst), .w0(W[1][0]),  .w1(W[1][1]),  .w2(W[1][2]),  .w3(W[1][3]),  .w4(W[1][4]),  .w5(W[1][5]),  .w6(W[1][6]),  .w7(W[1][7]),  .g0(g_obj1), .g1(g_obj2), .g2(g_obj3), .g3(g_obj4), .g4(g_obj5), .g5(g_obj6), .g6(g_obj7), .g7(g_obj8), .color_in(g_dir2),  .pf_input_i(g_in), .g_out(g_HDPC2),  .pf_spike_lif(HDPC_Spike2));
    OBJ_Neuron HDPC3  (.clk(clk), .rst(internal_rst), .w0(W[2][0]),  .w1(W[2][1]),  .w2(W[2][2]),  .w3(W[2][3]),  .w4(W[2][4]),  .w5(W[2][5]),  .w6(W[2][6]),  .w7(W[2][7]),  .g0(g_obj1), .g1(g_obj2), .g2(g_obj3), .g3(g_obj4), .g4(g_obj5), .g5(g_obj6), .g6(g_obj7), .g7(g_obj8), .color_in(g_dir3),  .pf_input_i(g_in), .g_out(g_HDPC3),  .pf_spike_lif(HDPC_Spike3));
    OBJ_Neuron HDPC4  (.clk(clk), .rst(internal_rst), .w0(W[3][0]),  .w1(W[3][1]),  .w2(W[3][2]),  .w3(W[3][3]),  .w4(W[3][4]),  .w5(W[3][5]),  .w6(W[3][6]),  .w7(W[3][7]),  .g0(g_obj1), .g1(g_obj2), .g2(g_obj3), .g3(g_obj4), .g4(g_obj5), .g5(g_obj6), .g6(g_obj7), .g7(g_obj8), .color_in(g_dir4),  .pf_input_i(g_in), .g_out(g_HDPC4),  .pf_spike_lif(HDPC_Spike4));
    OBJ_Neuron HDPC5  (.clk(clk), .rst(internal_rst), .w0(W[4][0]),  .w1(W[4][1]),  .w2(W[4][2]),  .w3(W[4][3]),  .w4(W[4][4]),  .w5(W[4][5]),  .w6(W[4][6]),  .w7(W[4][7]),  .g0(g_obj1), .g1(g_obj2), .g2(g_obj3), .g3(g_obj4), .g4(g_obj5), .g5(g_obj6), .g6(g_obj7), .g7(g_obj8), .color_in(g_dir5),  .pf_input_i(g_in), .g_out(g_HDPC5),  .pf_spike_lif(HDPC_Spike5));
    OBJ_Neuron HDPC6  (.clk(clk), .rst(internal_rst), .w0(W[5][0]),  .w1(W[5][1]),  .w2(W[5][2]),  .w3(W[5][3]),  .w4(W[5][4]),  .w5(W[5][5]),  .w6(W[5][6]),  .w7(W[5][7]),  .g0(g_obj1), .g1(g_obj2), .g2(g_obj3), .g3(g_obj4), .g4(g_obj5), .g5(g_obj6), .g6(g_obj7), .g7(g_obj8), .color_in(g_dir6),  .pf_input_i(g_in), .g_out(g_HDPC6),  .pf_spike_lif(HDPC_Spike6));
    OBJ_Neuron HDPC7  (.clk(clk), .rst(internal_rst), .w0(W[6][0]),  .w1(W[6][1]),  .w2(W[6][2]),  .w3(W[6][3]),  .w4(W[6][4]),  .w5(W[6][5]),  .w6(W[6][6]),  .w7(W[6][7]),  .g0(g_obj1), .g1(g_obj2), .g2(g_obj3), .g3(g_obj4), .g4(g_obj5), .g5(g_obj6), .g6(g_obj7), .g7(g_obj8), .color_in(g_dir7),  .pf_input_i(g_in), .g_out(g_HDPC7),  .pf_spike_lif(HDPC_Spike7));
    OBJ_Neuron HDPC8  (.clk(clk), .rst(internal_rst), .w0(W[7][0]),  .w1(W[7][1]),  .w2(W[7][2]),  .w3(W[7][3]),  .w4(W[7][4]),  .w5(W[7][5]),  .w6(W[7][6]),  .w7(W[7][7]),  .g0(g_obj1), .g1(g_obj2), .g2(g_obj3), .g3(g_obj4), .g4(g_obj5), .g5(g_obj6), .g6(g_obj7), .g7(g_obj8), .color_in(g_dir8),  .pf_input_i(g_in), .g_out(g_HDPC8),  .pf_spike_lif(HDPC_Spike8));
    OBJ_Neuron HDPC9  (.clk(clk), .rst(internal_rst), .w0(W[8][0]),  .w1(W[8][1]),  .w2(W[8][2]),  .w3(W[8][3]),  .w4(W[8][4]),  .w5(W[8][5]),  .w6(W[8][6]),  .w7(W[8][7]),  .g0(g_obj1), .g1(g_obj2), .g2(g_obj3), .g3(g_obj4), .g4(g_obj5), .g5(g_obj6), .g6(g_obj7), .g7(g_obj8), .color_in(g_dir9),  .pf_input_i(g_in), .g_out(g_HDPC9),  .pf_spike_lif(HDPC_Spike9));
    OBJ_Neuron HDPC10 (.clk(clk), .rst(internal_rst), .w0(W[9][0]),  .w1(W[9][1]),  .w2(W[9][2]),  .w3(W[9][3]),  .w4(W[9][4]),  .w5(W[9][5]),  .w6(W[9][6]),  .w7(W[9][7]),  .g0(g_obj1), .g1(g_obj2), .g2(g_obj3), .g3(g_obj4), .g4(g_obj5), .g5(g_obj6), .g6(g_obj7), .g7(g_obj8), .color_in(g_dir10), .pf_input_i(g_in), .g_out(g_HDPC10), .pf_spike_lif(HDPC_Spike10));
    OBJ_Neuron HDPC11 (.clk(clk), .rst(internal_rst), .w0(W[10][0]), .w1(W[10][1]), .w2(W[10][2]), .w3(W[10][3]), .w4(W[10][4]), .w5(W[10][5]), .w6(W[10][6]), .w7(W[10][7]), .g0(g_obj1), .g1(g_obj2), .g2(g_obj3), .g3(g_obj4), .g4(g_obj5), .g5(g_obj6), .g6(g_obj7), .g7(g_obj8), .color_in(g_dir11), .pf_input_i(g_in), .g_out(g_HDPC11), .pf_spike_lif(HDPC_Spike11));
    OBJ_Neuron HDPC12 (.clk(clk), .rst(internal_rst), .w0(W[11][0]), .w1(W[11][1]), .w2(W[11][2]), .w3(W[11][3]), .w4(W[11][4]), .w5(W[11][5]), .w6(W[11][6]), .w7(W[11][7]), .g0(g_obj1), .g1(g_obj2), .g2(g_obj3), .g3(g_obj4), .g4(g_obj5), .g5(g_obj6), .g6(g_obj7), .g7(g_obj8), .color_in(g_dir12), .pf_input_i(g_in), .g_out(g_HDPC12), .pf_spike_lif(HDPC_Spike12));
    OBJ_Neuron HDPC13 (.clk(clk), .rst(internal_rst), .w0(W[12][0]), .w1(W[12][1]), .w2(W[12][2]), .w3(W[12][3]), .w4(W[12][4]), .w5(W[12][5]), .w6(W[12][6]), .w7(W[12][7]), .g0(g_obj1), .g1(g_obj2), .g2(g_obj3), .g3(g_obj4), .g4(g_obj5), .g5(g_obj6), .g6(g_obj7), .g7(g_obj8), .color_in(g_dir13), .pf_input_i(g_in), .g_out(g_HDPC13), .pf_spike_lif(HDPC_Spike13));
    OBJ_Neuron HDPC14 (.clk(clk), .rst(internal_rst), .w0(W[13][0]), .w1(W[13][1]), .w2(W[13][2]), .w3(W[13][3]), .w4(W[13][4]), .w5(W[13][5]), .w6(W[13][6]), .w7(W[13][7]), .g0(g_obj1), .g1(g_obj2), .g2(g_obj3), .g3(g_obj4), .g4(g_obj5), .g5(g_obj6), .g6(g_obj7), .g7(g_obj8), .color_in(g_dir14), .pf_input_i(g_in), .g_out(g_HDPC14), .pf_spike_lif(HDPC_Spike14));
    OBJ_Neuron HDPC15 (.clk(clk), .rst(internal_rst), .w0(W[14][0]), .w1(W[14][1]), .w2(W[14][2]), .w3(W[14][3]), .w4(W[14][4]), .w5(W[14][5]), .w6(W[14][6]), .w7(W[14][7]), .g0(g_obj1), .g1(g_obj2), .g2(g_obj3), .g3(g_obj4), .g4(g_obj5), .g5(g_obj6), .g6(g_obj7), .g7(g_obj8), .color_in(g_dir15), .pf_input_i(g_in), .g_out(g_HDPC15), .pf_spike_lif(HDPC_Spike15));
    OBJ_Neuron HDPC16 (.clk(clk), .rst(internal_rst), .w0(W[15][0]), .w1(W[15][1]), .w2(W[15][2]), .w3(W[15][3]), .w4(W[15][4]), .w5(W[15][5]), .w6(W[15][6]), .w7(W[15][7]), .g0(g_obj1), .g1(g_obj2), .g2(g_obj3), .g3(g_obj4), .g4(g_obj5), .g5(g_obj6), .g6(g_obj7), .g7(g_obj8), .color_in(g_dir16), .pf_input_i(g_in), .g_out(g_HDPC16), .pf_spike_lif(HDPC_Spike16));
    OBJ_Neuron HDPC17 (.clk(clk), .rst(internal_rst), .w0(W[16][0]), .w1(W[16][1]), .w2(W[16][2]), .w3(W[16][3]), .w4(W[16][4]), .w5(W[16][5]), .w6(W[16][6]), .w7(W[16][7]), .g0(g_obj1), .g1(g_obj2), .g2(g_obj3), .g3(g_obj4), .g4(g_obj5), .g5(g_obj6), .g6(g_obj7), .g7(g_obj8), .color_in(g_dir17), .pf_input_i(g_in), .g_out(g_HDPC17), .pf_spike_lif(HDPC_Spike17));
    OBJ_Neuron HDPC18 (.clk(clk), .rst(internal_rst), .w0(W[17][0]), .w1(W[17][1]), .w2(W[17][2]), .w3(W[17][3]), .w4(W[17][4]), .w5(W[17][5]), .w6(W[17][6]), .w7(W[17][7]), .g0(g_obj1), .g1(g_obj2), .g2(g_obj3), .g3(g_obj4), .g4(g_obj5), .g5(g_obj6), .g6(g_obj7), .g7(g_obj8), .color_in(g_dir18), .pf_input_i(g_in), .g_out(g_HDPC18), .pf_spike_lif(HDPC_Spike18));

endmodule
