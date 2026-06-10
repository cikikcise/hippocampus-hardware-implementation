`timescale 1ns / 1ps

module learn_top #(
    parameter DATA_WIDTH = 20,
    parameter ADDR_WIDTH = 8,
    parameter MEM_FILE = "C3_weights.mem"
)(
    input wire clk,
    input wire rst,
    input wire update_req,               
    input wire signed [19:0] delta_w_in, // STDP'den gelen anlık Delta
    input wire [ADDR_WIDTH-1:0] neuron_addr,
    output reg signed [DATA_WIDTH-1:0] final_weight_out,
    output reg done2                     
);

    reg we;
    reg [ADDR_WIDTH-1:0] ram_addr;
    reg signed [DATA_WIDTH-1:0] ram_din;
    wire signed [DATA_WIDTH-1:0] ram_dout;

    DualPort_Neuron_Mem #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .MEM_FILE(MEM_FILE)
    ) weight_ram (
        .clk(clk),
        .wea(we),
        .addra(ram_addr),
        .dina(ram_din),
        .douta(ram_dout), 
        .web(1'b0),
        .addrb({ADDR_WIDTH{1'b0}}),
        .dinb({DATA_WIDTH{1'b0}}),
        .doutb() 
    );

    localparam S_IDLE       = 3'd0;
    localparam S_READ_REQ   = 3'd1;
    localparam S_WAIT_BRAM  = 3'd2;
    localparam S_WRITE_BRAM = 3'd3;
    localparam S_DONE       = 3'd4;

    reg [2:0] state;
    reg signed [20:0] temp_w;
    
    // İŞTE BÜTÜN SORUNU ÇÖZEN O KİLİT!
    reg signed [19:0] latched_delta; 
    reg [ADDR_WIDTH-1:0] latched_addr;

    always @(posedge clk) begin
        if (rst) begin
            state <= S_IDLE;
            we <= 1'b0;
            done2 <= 1'b0;
            ram_addr <= 0;
            final_weight_out <= 0;
            latched_delta <= 0;
        end else begin
            case (state)
                S_IDLE: begin
                    we <= 1'b0;
                    done2 <= 1'b0;
                    if (update_req) begin
                        ram_addr <= neuron_addr;
                        latched_addr <= neuron_addr;
                        // STDP'DEN GELEN DEĞERİ KAYBOLMADAN HEMEN KİLİTLE!
                        latched_delta <= delta_w_in; 
                        state <= S_READ_REQ;
                    end
                end
                
                S_READ_REQ: state <= S_WAIT_BRAM;
                
                S_WAIT_BRAM: begin
                    temp_w = ram_dout + latched_delta; 
                    
                    if (temp_w > 21'sd6144)        ram_din <= 20'sd6144;
                    else if (temp_w < -21'sd2048)  ram_din <= -20'sd2048;
                    else                           ram_din <= temp_w[19:0];
                    
                    we <= 1'b1; 
                    ram_addr <= latched_addr;
                    state <= S_WRITE_BRAM;
                end
                
                S_WRITE_BRAM: begin
                    we <= 1'b0;
                    final_weight_out <= ram_din; 
                    done2 <= 1'b1;               
                    state <= S_DONE;
                end
                
                S_DONE: begin
                    done2 <= 1'b0;
                    state <= S_IDLE;
                end
                
                default: state <= S_IDLE;
            endcase
        end
    end
endmodule
