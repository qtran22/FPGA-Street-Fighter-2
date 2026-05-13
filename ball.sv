//-------------------------------------------------------------------------
//    Ball.sv                                                            --
//    Viral Mehta                                                        --
//    Spring 2005                                                        --
//                                                                       --
//    Modified by Stephen Kempf     03-01-2006                           --
//                                  03-12-2007                           --
//    Translated by Joe Meng        07-07-2013                           --
//    Modified by Zuofu Cheng       08-19-2023                           --
//    Modified by Satvik Yellanki   12-17-2023                           --
//    Fall 2024 Distribution                                             --
//                                                                       --
//    For use with ECE 385 USB + HDMI Lab                                --
//    UIUC ECE Department                                                --
//-------------------------------------------------------------------------



module player1 (
    input  logic        Reset, 
    input  logic        frame_clk,
    input  logic [31:0] keycode,
    input  logic        got_hit,
    
    input  logic [9:0]  p2_posX,
    
    input  logic        am_ko,
    input  logic        opponent_ko,
    
    
    output logic [3:0]  state,
    output logic [3:0]  frame_index,
    output logic [9:0]  posX, 
    output logic [9:0]  posY
    
    
);

    parameter [9:0] X_INIT = 200;
    parameter [9:0] Y_INIT = 300;
    
    localparam IDLE_FRAMES = 4;
    localparam WALK_FRAMES = 6;
    localparam CROUCH_FRAMES = 3;
    localparam JUMP_FRAMES = 6;
    localparam PUNCH_FRAMES = 2;
    localparam KICK_FRAMES = 2;
    localparam HIT_FRAMES = 4;
    localparam KO_POSE_FRAMES = 5;
    localparam WIN_FRAMES = 3;
    localparam ANIMATION_SPEED = 8;
    
    localparam BODY_W = 40;  // collision body width in screen pixels
    
    localparam GROUND = 300;
    localparam JUMP_VEL = 15;
    localparam GRAVITY = 1;
    localparam MOVE_SPEED = 2;
    localparam KNOCKBACK_SPEED = 3;
    
    
    enum logic [3:0] {
        IDLE,
        RIGHT,
        LEFT,
        CROUCH,
        JUMP,
        PUNCH,
        KICK,
        HIT,
        KO,
        WIN
    } curr_state;
    
    logic [3:0] frame, animation_counter;
    logic ground;
    logic signed [9:0] vel_y;
    
    assign ground = (posY >= GROUND);
    
    assign state = curr_state;
    assign frame_index = frame;
    
    logic is_stunned;
    assign is_stunned = (curr_state == HIT);
    
    logic k_left, k_right, k_jump, k_crouch, k_punch, k_kick;
    always_comb begin
        k_left   = (keycode[7:0] == 8'h04) || (keycode[15:8] == 8'h04) || 
                   (keycode[23:16] == 8'h04) || (keycode[31:24] == 8'h04); // A
                   
        k_right  = (keycode[7:0] == 8'h07) || (keycode[15:8] == 8'h07) || 
                   (keycode[23:16] == 8'h07) || (keycode[31:24] == 8'h07); // D
                   
        k_jump   = (keycode[7:0] == 8'h1A) || (keycode[15:8] == 8'h1A) || 
                   (keycode[23:16] == 8'h1A) || (keycode[31:24] == 8'h1A); // W
                   
        k_crouch = (keycode[7:0] == 8'h16) || (keycode[15:8] == 8'h16) || 
                   (keycode[23:16] == 8'h16) || (keycode[31:24] == 8'h16); // S
                   
        k_punch  = (keycode[7:0] == 8'h09) || (keycode[15:8] == 8'h09) || 
                   (keycode[23:16] == 8'h09) || (keycode[31:24] == 8'h09); // F
                   
        k_kick   = (keycode[7:0] == 8'h2C) || (keycode[15:8] == 8'h2C) || 
                   (keycode[23:16] == 8'h2C) || (keycode[31:24] == 8'h2C); // Space
    end

    // --- CHANGED: Animation lock flag ---
    logic is_attacking;
    assign is_attacking = (curr_state == PUNCH) || (curr_state == KICK);

    always_ff @(posedge frame_clk or posedge Reset) begin
        if (Reset) begin
            posX <= X_INIT;
            posY <= Y_INIT;
            curr_state <= IDLE;
            frame <= 0;
            animation_counter <= 0;
            vel_y <= 0;
        end else begin
            
            if (am_ko) begin
                if (curr_state != KO) begin
                    curr_state        <= KO;
                    frame             <= 0;
                    animation_counter <= 0;
                end
            end 
            else if (opponent_ko) begin
                if (curr_state != WIN) begin
                    curr_state        <= WIN;
                    frame             <= 0;
                    animation_counter <= 0;
                end
            end else if (got_hit && curr_state != HIT) begin
                curr_state        <= HIT;
                frame             <= 0;
                animation_counter <= 0;
            end
            
            // --- CHANGED: Process inputs only if NOT locked in an attack ---
            else if (!is_attacking && !is_stunned && !am_ko && !opponent_ko) begin
                
                // Priority 1: Attacks
                if (k_punch && ground) begin
                    curr_state <= PUNCH;
                    frame <= 0;
                    animation_counter <= 0;
                end 
                else if (k_kick && ground) begin
                    curr_state <= KICK;
                    frame <= 0;
                    animation_counter <= 0;
                end
                // Priority 2: Jump
                else if (k_jump && ground) begin
                    vel_y <= -JUMP_VEL;
                    posY <= posY - 2;
                    curr_state <= JUMP;
                    frame <= 0; animation_counter <= 0;
                end
                // Priority 3: Crouch
                else if (k_crouch && ground) begin
                    if (curr_state != CROUCH) begin
                        curr_state <= CROUCH;
                        frame <= 0; animation_counter <= 0;
                    end
                end
                // Priority 4: Movement Left/Right
                else if (k_left && ground) begin
                    if (curr_state != LEFT) begin
                        curr_state <= LEFT;
                        frame <= 0; animation_counter <= 0;
                    end
                end
                else if (k_right && ground) begin
                    if (curr_state != RIGHT) begin
                        curr_state <= RIGHT;
                        frame <= 0; animation_counter <= 0;
                    end
                end
                // Priority 5: Default to Idle if grounded and not doing anything else
                else if (ground && curr_state != IDLE && curr_state != JUMP) begin
                    curr_state <= IDLE;
                    frame <= 0; animation_counter <= 0;
                end
                
            end

            // --- CHANGED: Apply horizontal movement (stops sliding if attacking) ---
            // Horizontal movement with collision
            if (curr_state == HIT && !am_ko && !opponent_ko) begin
                if (posX > 2)
                    posX <= posX - KNOCKBACK_SPEED;
            end else if ((!is_attacking || !ground) && !am_ko && !opponent_ko) begin
                if (k_left && posX > 2) begin
                    // Block only if P2 is to our left and we'd overlap
                    if (p2_posX < posX && posX - MOVE_SPEED < p2_posX + BODY_W)
                        posX <= p2_posX + BODY_W;
                    else
                        posX <= posX - MOVE_SPEED;
                end
                if (k_right && posX < 560) begin
                    // Block only if P2 is to our right and we'd overlap
                    if (p2_posX > posX && posX + MOVE_SPEED + BODY_W > p2_posX)
                        posX <= p2_posX - BODY_W;
                    else
                        posX <= posX + MOVE_SPEED;
                end
            end
             
            // Keep existing Gravity logic
            if (!ground) begin
                if ($signed(posY) + vel_y >= $signed(10'(GROUND))) begin
                    posY  <= GROUND;
                    vel_y <= 0;
                    if (curr_state == JUMP) begin
                        curr_state <= IDLE;
                        frame      <= 0;
                        animation_counter <= 0;
                    end
                end else begin
                    posY  <= posY + vel_y;
                    vel_y <= vel_y + GRAVITY;
                end
            end
             
            // Keep existing Animation Counter logic
            if (animation_counter == ANIMATION_SPEED - 1) begin
                animation_counter <= 0;
                case (curr_state)
                    IDLE: begin
                        if (frame == IDLE_FRAMES - 1) frame <= 0;
                        else frame <= frame + 1;
                    end
                    LEFT, RIGHT: begin
                        if (frame == WALK_FRAMES - 1) frame <= 0;
                        else frame <= frame + 1;
                    end
                    CROUCH: begin
                        if (frame == CROUCH_FRAMES - 1) frame <= 0;
                        else frame <= frame + 1;
                    end
                    JUMP: begin
                        if (frame == JUMP_FRAMES - 1) frame <= 0;
                        else frame <= frame + 1;
                    end
                    PUNCH: begin
                        if (frame == PUNCH_FRAMES - 1) begin
                            frame <= 0;
                            curr_state <= IDLE;
                        end else frame <= frame + 1;
                    end
                    KICK: begin
                        if (frame == KICK_FRAMES - 1) begin
                            frame <= 0;
                            curr_state <= IDLE;
                        end else frame <= frame + 1;
                    end
                    HIT: begin
                        if (frame == HIT_FRAMES - 1) begin
                            frame      <= 0;
                            curr_state <= ground ? IDLE : JUMP;
                        end else begin
                            frame <= frame + 1;
                        end
                    end
                    KO: begin
                        if (frame < KO_POSE_FRAMES - 1)
                            frame <= frame + 1;
                    end
                    WIN: begin
                        if (frame < WIN_FRAMES - 1)
                            frame <= frame + 1;
                    end
                    default: frame <= 0;
                endcase
            end else begin
                animation_counter <= animation_counter + 1;
            end
             
        end
    end

endmodule





module player2 (
    input  logic        Reset, 
    input  logic        frame_clk,
    input  logic [31:0] keycode,
    input  logic        got_hit,
    
    input  logic [9:0]  p1_posX,
    
    input  logic        am_ko,
    input  logic        opponent_ko,
    
    output logic [3:0]  state,
    output logic [3:0]  frame_index,
    output logic [9:0]  posX, 
    output logic [9:0]  posY
);

    parameter [9:0] X_INIT = 400;
    parameter [9:0] Y_INIT = 300;
    
    localparam IDLE_FRAMES = 4;
    localparam WALK_FRAMES = 6;
    localparam CROUCH_FRAMES = 3;
    localparam JUMP_FRAMES = 6;
    localparam PUNCH_FRAMES = 2;
    localparam KICK_FRAMES = 2;
    localparam CROUCH_KICK_FRAMES = 2;
    localparam CROUCH_PUNCH_FRAMES = 2;
    localparam HIT_FRAMES = 4;
    localparam KO_POSE_FRAMES = 5;
    localparam WIN_FRAMES = 3;
    localparam ANIMATION_SPEED = 8;
    
    localparam BODY_W = 40;
    
    localparam GROUND = 300;
    localparam JUMP_VEL = 15;
    localparam GRAVITY = 1;
    localparam MOVE_SPEED = 2;
    localparam KNOCKBACK_SPEED = 3;
    
    
    enum logic [3:0] {
        IDLE,
        RIGHT,
        LEFT,
        CROUCH,
        JUMP,
        PUNCH,
        KICK,
        HIT,
        KO,
        WIN
    } curr_state;
    
    logic [3:0] frame, animation_counter;
    logic ground;
    logic signed [9:0] vel_y;
    
    assign ground = (posY >= GROUND);
    
    assign state = curr_state;
    assign frame_index = frame;
    
    logic is_stunned;
    assign is_stunned = (curr_state == HIT);
    
    logic k_left, k_right, k_jump, k_crouch, k_punch, k_kick;
    always_comb begin
        k_left   = (keycode[7:0] == 8'h50) || (keycode[15:8] == 8'h50) || 
                   (keycode[23:16] == 8'h50) || (keycode[31:24] == 8'h50); // Left Arrow
                   
        k_right  = (keycode[7:0] == 8'h4F) || (keycode[15:8] == 8'h4F) || 
                   (keycode[23:16] == 8'h4F) || (keycode[31:24] == 8'h4F); // Right Arrow
                   
        k_jump   = (keycode[7:0] == 8'h52) || (keycode[15:8] == 8'h52) || 
                   (keycode[23:16] == 8'h52) || (keycode[31:24] == 8'h52); // Up Arrow
                   
        k_crouch = (keycode[7:0] == 8'h51) || (keycode[15:8] == 8'h51) || 
                   (keycode[23:16] == 8'h51) || (keycode[31:24] == 8'h51); // Down Arrow
                   
        k_punch  = (keycode[7:0] == 8'h37) || (keycode[15:8] == 8'h37) || 
                   (keycode[23:16] == 8'h37) || (keycode[31:24] == 8'h37); // Numpad / Custom Punch
                   
        k_kick   = (keycode[7:0] == 8'h36) || (keycode[15:8] == 8'h36) || 
                   (keycode[23:16] == 8'h36) || (keycode[31:24] == 8'h36); // Numpad / Custom Kick
    end

    // --- CHANGED: Animation lock flag ---
    logic is_attacking;
    assign is_attacking = (curr_state == PUNCH) || (curr_state == KICK);

    always_ff @(posedge frame_clk or posedge Reset) begin
        if (Reset) begin
            posX <= X_INIT;
            posY <= Y_INIT;
            curr_state <= IDLE;
            frame <= 0;
            animation_counter <= 0;
            vel_y <= 0;
        end else begin
            
            if (am_ko) begin
                if (curr_state != KO) begin
                    curr_state        <= KO;
                    frame             <= 0;
                    animation_counter <= 0;
                end
            end 
            else if (opponent_ko) begin
                if (curr_state != WIN) begin
                    curr_state        <= WIN;
                    frame             <= 0;
                    animation_counter <= 0;
                end
            end else if (got_hit && curr_state != HIT) begin
                curr_state        <= HIT;
                frame             <= 0;
                animation_counter <= 0;
            end
            
            // --- CHANGED: Process inputs only if NOT locked in an attack ---
            else if (!is_attacking && !is_stunned && !am_ko && !opponent_ko) begin
                
                // Priority 1: Attacks
                if (k_punch && ground) begin
                    curr_state <= PUNCH;
                    frame <= 0;
                    animation_counter <= 0;
                end 
                else if (k_kick && ground) begin
                    curr_state <= KICK;
                    frame <= 0;
                    animation_counter <= 0;
                end
                // Priority 2: Jump
                else if (k_jump && ground) begin
                    vel_y <= -JUMP_VEL;
                    posY <= posY - 2;
                    curr_state <= JUMP;
                    frame <= 0; animation_counter <= 0;
                end
                // Priority 3: Crouch
                else if (k_crouch && ground) begin
                    if (curr_state != CROUCH) begin
                        curr_state <= CROUCH;
                        frame <= 0; animation_counter <= 0;
                    end
                end
                // Priority 4: Movement Left/Right
                else if (k_left && ground) begin
                    if (curr_state != LEFT) begin
                        curr_state <= LEFT;
                        frame <= 0; animation_counter <= 0;
                    end
                end
                else if (k_right && ground) begin
                    if (curr_state != RIGHT) begin
                        curr_state <= RIGHT;
                        frame <= 0; animation_counter <= 0;
                    end
                end
                // Priority 5: Default to Idle if grounded and not doing anything else
                else if (ground && curr_state != IDLE && curr_state != JUMP) begin
                    curr_state <= IDLE;
                    frame <= 0; animation_counter <= 0;
                end
                
            end

            // --- CHANGED: Apply horizontal movement ---
            if (curr_state == HIT && !am_ko && !opponent_ko) begin
                if (posX < 560)
                    posX <= posX + KNOCKBACK_SPEED;
            end else if ((!is_attacking || !ground) && !am_ko && !opponent_ko) begin
                if (k_left && posX > 2) begin
                    if (p1_posX < posX && posX - MOVE_SPEED < p1_posX + BODY_W)
                        posX <= p1_posX + BODY_W;
                    else
                        posX <= posX - MOVE_SPEED;
                end
                if (k_right && posX < 560) begin
                    if (p1_posX > posX && posX + MOVE_SPEED + BODY_W > p1_posX)
                        posX <= p1_posX - BODY_W;
                    else
                        posX <= posX + MOVE_SPEED;
                end
            end
             
            // Keep existing Gravity logic
            if (!ground) begin
                if ($signed(posY) + vel_y >= $signed(10'(GROUND))) begin
                    posY  <= GROUND;
                    vel_y <= 0;
                    if (curr_state == JUMP) begin
                        curr_state <= IDLE;
                        frame      <= 0;
                        animation_counter <= 0;
                    end
                end else begin
                    posY  <= posY + vel_y;
                    vel_y <= vel_y + GRAVITY;
                end
            end
             
            // Keep existing Animation Counter logic
            if (animation_counter == ANIMATION_SPEED - 1) begin
                animation_counter <= 0;
                case (curr_state)
                    IDLE: begin
                        if (frame == IDLE_FRAMES - 1) frame <= 0;
                        else frame <= frame + 1;
                    end
                    LEFT, RIGHT: begin
                        if (frame == WALK_FRAMES - 1) frame <= 0;
                        else frame <= frame + 1;
                    end
                    CROUCH: begin
                        if (frame == CROUCH_FRAMES - 1) frame <= 0;
                        else frame <= frame + 1;
                    end
                    JUMP: begin
                        if (frame == JUMP_FRAMES - 1) frame <= 0;
                        else frame <= frame + 1;
                    end
                    PUNCH: begin
                        if (frame == PUNCH_FRAMES - 1) begin
                            frame <= 0;
                            curr_state <= IDLE;
                        end else frame <= frame + 1;
                    end
                    KICK: begin
                        if (frame == KICK_FRAMES - 1) begin
                            frame <= 0;
                            curr_state <= IDLE;
                        end else frame <= frame + 1;
                    end
                    HIT: begin
                        if (frame == HIT_FRAMES - 1) begin
                            frame      <= 0;
                            curr_state <= ground ? IDLE : JUMP;
                        end else begin
                            frame <= frame + 1;
                        end
                    end
                    KO: begin
                        if (frame < KO_POSE_FRAMES - 1)
                            frame <= frame + 1;
                    end
                    WIN: begin
                        if (frame < WIN_FRAMES - 1)
                            frame <= frame + 1;
                    end
                    default: frame <= 0;
                endcase
            end else begin
                animation_counter <= animation_counter + 1;
            end
             
        end
    end

endmodule




