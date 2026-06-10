`timescale 1ns / 1ps

module conductance(
    input  wire clk,
    input  wire rst,
    input  wire spike,
    input wire signed [19:0] g_sym,
    output reg  signed [19:0] g_out,
    output reg  signed [19:0] counter_out 
);


    //parameter signed [19:0] g_sym = 20'sd164; // 40 mSiemens
    parameter signed [19:0] tau   = 20'sd820; // 5 ms 
    parameter signed [19:0] G_MAX = 20'sd200000;

    // FSM
    localparam IDLE  = 2'd0;
    localparam SPIKE = 2'd1;
    localparam DECAY = 2'd2;

    reg [1:0] state, next_state;

   
    reg signed [19:0] counter;
    reg signed [19:0] g_ref; 

    // -------------------------------
    // Wires
    // -------------------------------
    wire signed [39:0] mult1;
    wire signed [19:0] decay_in;
    wire signed [19:0] decay_factor;
    wire signed [39:0] mult2;
    wire signed [19:0] mult3;

    // EXP Block
    exp_1 exp_decay (
        .exp_in  (decay_in),
        .exp_out (decay_factor)
    );


    assign mult1    = counter * tau;
    assign decay_in = -(mult1 >>> 8);
    assign mult2    = g_ref * decay_factor;
    assign mult3    = mult2 >>> 12;


    always @(posedge clk or posedge rst) begin
        if (rst)
            state <= IDLE;
        else
            state <= next_state;
    end


    always @(*) begin
        case (state)
            IDLE: begin
                if (spike)
                    next_state = SPIKE;
                else
                    next_state = IDLE;
            end

            SPIKE: begin
                next_state = DECAY;
            end

            DECAY: begin
                if (spike)
                    next_state = SPIKE;
                
                else if (mult3 <= 20'sd0 || counter > 20'sd524000)
                    next_state = IDLE;
                else
                    next_state = DECAY;
            end

            default: next_state = IDLE;
        endcase
    end


    always @(posedge clk or posedge rst) begin
        if (rst) begin
            counter     <= 20'sd0;
            counter_out <= 20'sd0;
            g_out       <= 20'sd0;
            g_ref       <= 20'sd0;

        end else begin
            case (state)

                IDLE: begin
                    counter     <= 20'sd0;
                    counter_out <= 20'sd0;
                    g_out       <= 20'sd0;
                    g_ref       <= 20'sd0;
                end

                SPIKE: begin
                    counter     <= 20'sd0;            
                    counter_out <= 20'sd0;
                    if ((g_out + g_sym) > G_MAX)
                        g_ref <= G_MAX;
                    else
                        g_ref <= g_out + g_sym;      
                end

                DECAY: begin
                    counter     <= counter + 20'sd1;
                    counter_out <= counter + 20'sd1;

                    if (mult3 > 20'sd0)
                        g_out <= mult3;
                    else begin
                        g_out <= 20'sd0;
                        g_ref <= 20'sd0;
                    end
                end

                default: begin
                    counter     <= 20'sd0;
                    counter_out <= 20'sd0;
                    g_out       <= 20'sd0;
                    g_ref       <= 20'sd0;
                end
            endcase
        end
    end

endmodule
