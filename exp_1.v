`timescale 1ns / 1ps

module exp_1 (
    input wire signed [19:0] exp_in,
    output reg signed [19:0] exp_out
);
    
// Q3.16 fixed-point format
parameter signed [19:0] C_6_3  = 20'b01100100110111001100;
parameter signed [19:0] C_2_7  = 20'b00101011001101000011;
parameter signed [19:0] C_1    = 20'b00010000000000000000;
parameter signed [19:0] C_LOGE = 20'b00000110111101110111; // 0.434

parameter [15:0] Q0_16_ONE = 16'h10000; 

wire is_zero = (exp_in == 20'b0);

// y = exp_in * log10(e) (Q3.16 * Q3.16 = Q6.32 -> Q3.16)
wire signed [39:0] y_b = exp_in * C_LOGE;
wire signed [19:0] y = y_b[35:16]; 

wire y_neg = y[19];
wire signed [19:0] y_abs = y_neg ? (~y + 20'd1) : y; // |y|

wire [2:0] z_mag = y_abs[18:16]; // |z| integer part
wire [15:0] x_mag = y_abs[15:0]; // |x| decimal part

wire signed [2:0] neg_z_mag = ~z_mag + 3'd1; // -|z|

wire signed [2:0] z;
assign z = y_neg ? ((x_mag != 16'h0) ? (neg_z_mag - 3'd1) : neg_z_mag) : z_mag; 

wire [15:0] x; 
assign x = (y_neg && (x_mag != 16'h0)) ? (Q0_16_ONE - x_mag) : x_mag; 


wire signed [19:0] dec_fp = $signed({4'b0000, x}); 

wire signed [39:0] dec2_fp = dec_fp * dec_fp;
wire signed [19:0] dec2 = dec2_fp[35:16]; // x^2

wire signed [39:0] dec3_fp = dec2 * dec_fp; 
wire signed [19:0] dec3 = dec3_fp[35:16]; // x^3

wire signed [39:0] term1_fp = C_2_7 * dec_fp;
wire signed [19:0] term1 = term1_fp[35:16];

wire signed [39:0] term2_fp = C_6_3 * dec3;
wire signed [19:0] term2 = term2_fp[35:16];


wire signed [20:0] ext_C1    = {C_1[19], C_1};
wire signed [20:0] ext_term1 = {term1[19], term1};
wire signed [20:0] ext_term2 = {term2[19], term2};

wire signed [20:0] exp_decimal = ext_C1 + ext_term1 + ext_term2; 

reg signed [31:0] pow10_table [0:7];
initial begin
    pow10_table[0] = 32'sd4096;      // 10^0 (Qx.12)
    pow10_table[1] = 32'sd40960;     // 10^1
    pow10_table[2] = 32'sd409600;    // 10^2
    pow10_table[3] = 32'sd4096000;   // 10^3
    pow10_table[4] = 32'sd40960000;  // 10^4 
    pow10_table[5] = 32'sd410;       // 10^-1
    pow10_table[6] = 32'sd41;        // 10^-2
    pow10_table[7] = 32'sd4;         // 10^-3
end

wire z_is_neg = z[2];
wire [2:0] z_abs = z_is_neg ? (~z + 3'd1) : z; 

wire [2:0] z_index;
assign z_index = z_is_neg ? (z_abs + 3'd4) : z_abs; 

wire signed [31:0] ten_int = pow10_table[z_index];

//32-bit (Qx.12) * 21-bit (Q4.16) = 53-bit (Qx.28)
wire signed [52:0] full_pow10 = ten_int * exp_decimal;


wire signed [19:0] full_pow10_trunc = full_pow10[35:16]; 

wire signed [19:0] result;

// Underflow detection: If y <= -3.0, the exponential result approaches zero.
wire neg_underflow = (y_neg && (y_abs >= 20'd196608)); 

// Saturation Control
wire signed [19:0] max_pos_val = 20'h7FFFF; 
wire overflow_flag = (full_pow10_trunc > max_pos_val) || (full_pow10_trunc[19] == 1'b1);

assign result = is_zero                   ? 20'd4096      : 
                neg_underflow             ? 20'sd0        : 
                (overflow_flag && !y_neg) ? max_pos_val   : 
                full_pow10_trunc; 

always @(*) begin
    exp_out = result;
end

endmodule
