`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/27/2026 10:47:49 PM
// Design Name: 
// Module Name: hitbox
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


module hitbox (
    input logic         clk,
    input logic         Reset,
    input logic [9:0]   p1_x, p1_y,
    input logic [3:0]   p1_state, p1_frame,
    input logic [9:0]   p2_x, p2_y,
    input logic [3:0]   p2_state, p2_frame,
    output logic        p1_hit,
    output logic        p2_hit
);

    localparam IDLE     = 4'd0;
    localparam RIGHT    = 4'd1;
    localparam LEFT     = 4'd2;
    localparam CROUCH   = 4'd3;
    localparam JUMP     = 4'd4;
    localparam PUNCH    = 4'd5;
    localparam KICK     = 4'd6;

    // -------------------------------------------------------
    // HURTBOXES (the box that receives damage)
    // These shrink/shift based on stance
    // p1_y and p2_y should already reflect jump arc in your
    // game logic. If they don't, you'll need a separate offset.
    // -------------------------------------------------------

    logic [10:0] p1_hurt_x1, p1_hurt_y1, p1_hurt_x2, p1_hurt_y2;
    always_comb begin
        // Default: standing hurtbox
        // At SCALE=2, sprite is 80px wide (40*2) and 128px tall (64*2)
        p1_hurt_x1 = p1_x + 10;      // slight inset on sides
        p1_hurt_y1 = p1_y;
        p1_hurt_x2 = p1_x + 70;
        p1_hurt_y2 = p1_y + 128;

        case (p1_state)
            CROUCH: begin
                // Crouching: taller bottom half only, upper body protected
                p1_hurt_x1 = p1_x + 5;
                p1_hurt_y1 = p1_y + 64;   // only lower half exposed
                p1_hurt_x2 = p1_x + 75;
                p1_hurt_y2 = p1_y + 128;
            end
            JUMP: begin
                // Jumping: p1_y moves up with arc, so box follows naturally
                // Slightly narrower since limbs are tucked
                p1_hurt_x1 = p1_x + 15;
                p1_hurt_y1 = p1_y;
                p1_hurt_x2 = p1_x + 65;
                p1_hurt_y2 = p1_y + 128;
            end
            default: begin
                p1_hurt_x1 = p1_x + 10;
                p1_hurt_y1 = p1_y;
                p1_hurt_x2 = p1_x + 70;
                p1_hurt_y2 = p1_y + 128;
            end
        endcase
    end

    logic [10:0] p2_hurt_x1, p2_hurt_y1, p2_hurt_x2, p2_hurt_y2;
    always_comb begin
        p2_hurt_x1 = p2_x + 10;
        p2_hurt_y1 = p2_y;
        p2_hurt_x2 = p2_x + 70;
        p2_hurt_y2 = p2_y + 128;

        case (p2_state)
            CROUCH: begin
                p2_hurt_x1 = p2_x + 5;
                p2_hurt_y1 = p2_y + 64;
                p2_hurt_x2 = p2_x + 75;
                p2_hurt_y2 = p2_y + 128;
            end
            JUMP: begin
                p2_hurt_x1 = p2_x + 15;
                p2_hurt_y1 = p2_y;
                p2_hurt_x2 = p2_x + 65;
                p2_hurt_y2 = p2_y + 128;
            end
            default: begin
                p2_hurt_x1 = p2_x + 10;
                p2_hurt_y1 = p2_y;
                p2_hurt_x2 = p2_x + 70;
                p2_hurt_y2 = p2_y + 128;
            end
        endcase
    end

    // -------------------------------------------------------
    // P1 HITBOXES
    // P1 faces RIGHT by default (p1_flip logic in renderer
    // means P1 faces toward P2, so extend hitbox to the right)
    // -------------------------------------------------------

    logic [10:0] p1_hit_x1, p1_hit_y1, p1_hit_x2, p1_hit_y2;
    logic p1_attacking;

    always_comb begin
        p1_attacking = 1'b0;
        p1_hit_x1 = 0; p1_hit_y1 = 0;
        p1_hit_x2 = 0; p1_hit_y2 = 0;

        case (p1_state)
            PUNCH: begin
                // Renderer: only 2 frames (0=windup, 1=extension)
                if (p1_frame == 1) begin
                    p1_attacking = 1'b1;
                    // Fist extends to the right
                    p1_hit_x1 = p1_x + 70;
                    p1_hit_y1 = p1_y + 20;
                    p1_hit_x2 = p1_x + 120; // 60px reach
                    p1_hit_y2 = p1_y + 60;
                end
            end
            KICK: begin
                // Renderer: only 2 frames (0=windup, 1=extension)
                if (p1_frame == 1) begin
                    p1_attacking = 1'b1;
                    // Foot extends to the right, lower on body
                    p1_hit_x1 = p1_x + 60;
                    p1_hit_y1 = p1_y + 70;
                    p1_hit_x2 = p1_x + 150; // kicks have more reach
                    p1_hit_y2 = p1_y + 110;
                end
            end
            default: p1_attacking = 1'b0;
        endcase
    end

    // -------------------------------------------------------
    // P2 HITBOXES
    // KEY FIX: P2 faces LEFT so hitbox extends to the LEFT.
    // We use signed subtraction to avoid underflow.
    // -------------------------------------------------------

    logic signed [10:0] p2_x_s; // signed version to safely subtract
    assign p2_x_s = {1'b0, p2_x};

    logic [10:0] p2_hit_x1, p2_hit_y1, p2_hit_x2, p2_hit_y2;
    logic p2_attacking;

    always_comb begin
        p2_attacking = 1'b0;
        p2_hit_x1 = 0; p2_hit_y1 = 0;
        p2_hit_x2 = 0; p2_hit_y2 = 0;
    
        case (p2_state)
            PUNCH: begin
                if (p2_frame == 1) begin
                    p2_attacking = 1'b1;
                    p2_hit_x2 = p2_x + 10;
                    p2_hit_x1 = (p2_x_s - 11'd60 > 0) ? p2_x - 60 : 0;  // was 110, now 60px reach
                    p2_hit_y1 = p2_y + 20;
                    p2_hit_y2 = p2_y + 60;
                end
            end
            KICK: begin
                if (p2_frame == 1) begin
                    p2_attacking = 1'b1;
                    p2_hit_x2 = p2_x + 10;
                    p2_hit_x1 = (p2_x_s - 11'd80 > 0) ? p2_x - 80 : 0;  // keep kick reach longer
                    p2_hit_y1 = p2_y + 70;
                    p2_hit_y2 = p2_y + 110;
                end
            end
            default: p2_attacking = 1'b0;
        endcase
    end

    // -------------------------------------------------------
    // OVERLAP DETECTION
    // Two AABBs overlap when they are NOT separated on any axis
    // -------------------------------------------------------

    logic p1_hits_p2, p2_hits_p1;

    assign p1_hits_p2 = p1_attacking &&
                        (p1_x < p2_x) &&   // P1 must be to the left of P2  
                        (p1_hit_x1 < p2_hurt_x2) && (p1_hit_x2 > p2_hurt_x1) &&
                        (p1_hit_y1 < p2_hurt_y2) && (p1_hit_y2 > p2_hurt_y1);

    assign p2_hits_p1 = p2_attacking &&
                        (p2_x > p1_x) &&   // P2 must be to the right of P1
                        (p2_hit_x1 < p1_hurt_x2) && (p2_hit_x2 > p1_hurt_x1) &&
                        (p2_hit_y1 < p1_hurt_y2) && (p2_hit_y2 > p1_hurt_y1);

    // -------------------------------------------------------
    // EDGE DETECTION - only pulse on the rising edge of a hit
    // so HP only decrements once per attack, not every frame
    // -------------------------------------------------------

    logic p1_hits_p2_prev, p2_hits_p1_prev;

    always_ff @(posedge clk or posedge Reset) begin
        if (Reset) begin
            p1_hits_p2_prev <= 0;
            p2_hits_p1_prev <= 0;
        end else begin
            p1_hits_p2_prev <= p1_hits_p2;
            p2_hits_p1_prev <= p2_hits_p1;
        end
    end

    assign p2_hit = p1_hits_p2 && !p1_hits_p2_prev;
    assign p1_hit = p2_hits_p1 && !p2_hits_p1_prev;

endmodule