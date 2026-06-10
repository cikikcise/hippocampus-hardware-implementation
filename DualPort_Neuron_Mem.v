`timescale 1ns / 1ps

module DualPort_Neuron_Mem #(
    parameter DATA_WIDTH = 20,         // STDP modülünle uyumlu olması için 20 yaptık
    parameter ADDR_WIDTH = 6,         
    parameter MEM_FILE = "weights.mem"
)(
    input clk,

    // Port A: Okuma/Yazma
    input wea,
    input [ADDR_WIDTH-1:0] addra,
    input [DATA_WIDTH-1:0] dina,
    output reg [DATA_WIDTH-1:0] douta,

    // Port B: Okuma/Yazma (Öğrenme Algoritması için)
    input web,
    input [ADDR_WIDTH-1:0] addrb,
    input [DATA_WIDTH-1:0] dinb,
    output reg [DATA_WIDTH-1:0] doutb
);

    // BRAM Donanımı Tanımlama
    (* ram_style = "block" *) reg [DATA_WIDTH-1:0] ram [0:(2**ADDR_WIDTH)-1];

    // Başlangıç değerlerini .mem dosyasından yükle
    initial begin
        if (MEM_FILE != "") begin
            $readmemh(MEM_FILE, ram);
        end
    end

    // TEK BİR ALWAYS BLOĞU: Port A ve Port B çakışmasını önler
    always @(posedge clk) begin
        // Port A İşlemi
        if (wea) begin
            ram[addra] <= dina;
        end
        douta <= ram[addra];

        // Port B İşlemi
        if (web) begin
            ram[addrb] <= dinb;
        end
        doutb <= ram[addrb];
    end

endmodule
