`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/22/2026 03:18:27 AM
// Design Name: 
// Module Name: health_bar
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module health_bar (
    input logic         clk,
    input logic         Reset,
    input logic         p1_hit,
    input logic         p2_hit,
    input logic [7:0]   p1_damage,
    input logic [7:0]   p2_damage,
    output logic [15:0] p1_hp,
    output logic [15:0] p2_hp,
    output logic        p1_ko,
    output logic        p2_ko
);

    localparam HP = 100;
    
    always_ff @(posedge clk or posedge Reset) begin
        if (Reset) begin
            p1_hp <= HP;
            p2_hp <= HP;
        end else begin
            if (p1_hit) begin
                if (p1_hp > p1_damage) 
                    p1_hp <= p1_hp - p1_damage;
                else
                    p1_hp <= 0;
            end
            
            if (p2_hit) begin
                if (p2_hp > p2_damage)
                    p2_hp <= p2_hp - p2_damage;
                else
                    p2_hp <= 0;
            end
        end
    end
    
    assign p1_ko = (p1_hp == 0);
    assign p2_ko = (p2_hp == 0);
        
    
endmodule
