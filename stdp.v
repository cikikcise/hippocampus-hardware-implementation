`timescale 1ns / 1ps

module stdp(
    input wire clk, 
    input wire rst, 
    input wire pre_spike, 
    input wire post_spike, 
    output reg signed [19:0] delta_w,
    output reg done,
    output reg [19:0] current_count1,
    output reg [19:0] current_count2,
    output reg signed [19:0] exp_in_out,
    output reg signed [19:0] exp_out_out
);

// --- Değişken Tanımlamaları ---
reg signed [19:0] exp_in; 
reg signed [42:0] mult_result; 
reg signed [42:0] mult_tmp; 

parameter signed [19:0] A_PLUS = 20'sd4218; 
parameter signed [19:0] A_MINUS = 20'sd2088; 
parameter signed [19:0] INV_TAU_PLUS = 20'd293; 
parameter signed [19:0] INV_TAU_MINUS = 20'd120; 

reg [19:0] real_count1; // Pre spike sayacı
reg [19:0] real_count2; // Post spike sayacı

// 4096 clock -> 10 ms = 40960 clock
parameter [19:0] TIMEOUT_LIMIT = 20'd40960; 
parameter [19:0] INVALID_TIME = 20'hFFFFF; 

wire signed [19:0] exp_out; 
exp_1 exp_module ( .exp_in(exp_in), .exp_out(exp_out) ); 
 
parameter IDLE = 3'b000; 
parameter POT = 3'b010; 
parameter DEP = 3'b011; 
parameter BOTH_PRE_POST = 3'b101; 
 
reg [2:0] state, next_state; 
 
// =========================================================================
// 1. TAM BAĞIMSIZ VE TÜKETİLEBİLİR SAYAÇLAR (NEAREST-NEIGHBOR)
// =========================================================================
always @(posedge clk or posedge rst) begin
    if (rst == 1'b1) begin
        real_count1 <= INVALID_TIME;
        real_count2 <= INVALID_TIME;
    end else begin
        // ---------------------------------------------------------
        // PRE SAYAÇ (real_count1) İşlemleri
        // ---------------------------------------------------------
        if (pre_spike) begin
            real_count1 <= 20'd0; // Pre geldi, sayacı sıfırla
        end 
        else if (state == POT) begin
            real_count1 <= INVALID_TIME; 
        end 
        else if (real_count1 != INVALID_TIME) begin
            if (real_count1 >= TIMEOUT_LIMIT) 
                real_count1 <= INVALID_TIME; // 10 ms geçince zaman penceresini kapat
            else 
                real_count1 <= real_count1 + 20'd1; 
        end

        // ---------------------------------------------------------
        // POST SAYAÇ (real_count2) İşlemleri
        // ---------------------------------------------------------
        if (post_spike) begin
            real_count2 <= 20'd0; // Post geldi, sayacı sıfırla
        end 
        else if (state == DEP) begin
            real_count2 <= INVALID_TIME;
        end 
        else if (real_count2 != INVALID_TIME) begin
            if (real_count2 >= TIMEOUT_LIMIT) 
                real_count2 <= INVALID_TIME;
            else 
                real_count2 <= real_count2 + 20'd1; 
        end
    end
end

// Durum Güncellemesi
always @(posedge clk or posedge rst) begin
  if (rst == 1'b1) state <= IDLE;
  else state <= next_state;
end

// =========================================================================
// 2. FSM DURUM VE HESAPLAMA
// =========================================================================
always @(*) begin 
    next_state = state;
    mult_tmp = 43'd0;
    exp_in = 20'd0;
    mult_result = 43'd0;

    if (rst) next_state = IDLE; 
    else begin 
        case (state) 
            IDLE: begin 
                if (pre_spike && post_spike) next_state = BOTH_PRE_POST; 
                else if (post_spike) next_state = POT; 
                else if (pre_spike) next_state = DEP; 
                else next_state = IDLE; 
            end 
            POT: begin 
                next_state = IDLE; 
                // Geçerli bir zaman penceresi varsa LTP hesapla
                if (real_count1 != INVALID_TIME && real_count1 <= TIMEOUT_LIMIT) begin 
                    mult_tmp = real_count1 * INV_TAU_PLUS; 
                    exp_in = -(mult_tmp >>> 8);
                    mult_result = A_PLUS * exp_out; 
                end
            end 
            DEP: begin 
                next_state = IDLE; 
                // Geçerli bir zaman penceresi varsa LTD hesapla
                if (real_count2 != INVALID_TIME && real_count2 <= TIMEOUT_LIMIT) begin 
                    mult_tmp = real_count2 * INV_TAU_MINUS; 
                    exp_in =  -(mult_tmp >>> 8); 
                    mult_result = A_MINUS * exp_out; 
                end
            end 
            BOTH_PRE_POST: begin 
                next_state = IDLE; 
            end 
            default: next_state = IDLE; 
        endcase 
    end 
end 

// =========================================================================
// 3. ÇIKIŞ ATAMALARI
// =========================================================================
always @(posedge clk or posedge rst) begin
    if (rst) begin
        delta_w <= 20'b0;
        done <= 1'b0; 
    end else begin
        case (state) 
            POT: begin 
                // Sadece hesaplama başarılıysa ağırlığı güncelle 
                if (real_count1 != INVALID_TIME && real_count1 <= TIMEOUT_LIMIT) begin
                    delta_w <= mult_result >>> 12; 
                    done <= 1'b1; 
                end else begin
                    delta_w <= 20'b0; 
                    done <= 1'b0; 
                end
            end 
            DEP: begin 
                // Sadece hesaplama başarılıysa ağırlığı güncelle 
                if (real_count2 != INVALID_TIME && real_count2 <= TIMEOUT_LIMIT) begin
                    delta_w <= -(mult_result >>> 12); 
                    done <= 1'b1; 
                end else begin
                    delta_w <= 20'b0;
                    done <= 1'b0; 
                end
            end 
            BOTH_PRE_POST: begin 
                delta_w <= A_PLUS;
                done <= 1'b1;
            end 
            IDLE: begin
                delta_w <= 20'b0; 
                done <= 1'b0;
            end
            default: begin
                delta_w <= 20'b0; 
                done <= 1'b0;
            end
        endcase 
    end 
end 
    
// Çıkış kabloları atamaları
always @(*) begin
    current_count1 = real_count1;
    current_count2 = real_count2;
    exp_in_out = exp_in;
    exp_out_out = exp_out;
end

endmodule
