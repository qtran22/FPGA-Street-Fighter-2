//-------------------------------------------------------------------------
//    Color_Mapper.sv                                                    --
//    Stephen Kempf                                                      --
//    3-1-06                                                             --
//                                                                       --
//    Modified by David Kesler  07-16-2008                               --
//    Translated by Joe Meng    07-07-2013                               --
//    Modified by Zuofu Cheng   08-19-2023                               --
//                                                                       --
//    Fall 2023 Distribution                                             --
//                                                                       --
//    For use with ECE 385 USB + HDMI                                    --
//    University of Illinois ECE Department                              --
//-------------------------------------------------------------------------


module sprite_renderer (
    input logic       vga_clk,
    input logic [9:0] DrawX, DrawY,

    input logic [9:0] p1_x, p1_y,
    input logic [3:0] p1_state,
    input logic [3:0] p1_frame,
    input logic [15:0] p1_hp, p2_hp,
    input logic [3:0] p2_state,
    input logic [3:0] p2_frame,
    input logic [9:0] p2_x, p2_y,
    
    input logic       ko_flag,
    input logic       title_screen,  

    output logic [3:0] Red, Green, Blue
);

    localparam SPRITE_H = 51;
    localparam P1_IMG_W = 315;
    localparam P2_IMG_W = 355;
    localparam SCALE = 2;
    
    localparam IDLE = 0;
    localparam RIGHT = 1;
    localparam LEFT = 2;
    localparam CROUCH = 3;
    localparam JUMP = 4;
    localparam KO_ANIM  = 8;
    localparam WIN_ANIM = 9;
    
    localparam SCREEN_W = 640;
    localparam BG_W = 1024;
    
    localparam KO_W = 320;
    localparam KO_H = 109;
    localparam KO_SHEET_W = 320;
    localparam KO_SHEET_H = 109;
    localparam KO_X = (640 - KO_W*2)/2;  
    localparam KO_Y = (480 - KO_H*2)/2;
    
    localparam P1_KO_H  = 34;
    localparam P1_WIN_H = 67;
    
    localparam P2_KO_H  = 47;
    localparam P2_WIN_H = 65;
    
    logic [15:0] p1_hp_bar, p2_hp_bar;
    assign p1_hp_bar = (p1_hp * 250) / 100;
    assign p2_hp_bar = (p2_hp * 250) / 100;
    
    logic p1_hp_active, p2_hp_active, ko_ui_active;
    logic p1_hp_bg, p2_hp_bg;
    logic p1_hp_border, p2_hp_border;
    
    assign p1_hp_border = (DrawX >= 50 - 2) &&
                          (DrawX < 50 + 250 + 2) &&
                          (DrawY >= 50 - 2) &&
                          (DrawY < 75 + 2);
             
                          
    assign p2_hp_border = (DrawX >= 340 - 2) &&
                          (DrawX < 340 + 250 + 2) &&
                          (DrawY >= 50 - 2) &&
                          (DrawY < 75 + 2);
    
    
    assign p1_hp_active = (DrawX >= 300 - p1_hp_bar) && 
                          (DrawX <  300) &&
                          (DrawY >= 50) && 
                          (DrawY <  75);
    
  
    assign p1_hp_bg = (DrawX >= 50) && 
                      (DrawX <  50 + 250) &&
                      (DrawY >= 50) && 
                      (DrawY <  75);
    
    
    assign ko_ui_active = (DrawX >= 300)  && 
                       (DrawX < 340) &&
                       (DrawY >= 50)  && 
                       (DrawY <  75);
                       
    assign p2_hp_active = (DrawX >= 340) && 
                          (DrawX <  340 + p2_hp_bar) &&
                          (DrawY >= 50) && 
                          (DrawY <  75);
    
   
    assign p2_hp_bg = (DrawX >= 340) && 
                      (DrawX <  340 + 250) &&
                      (DrawY >= 50) && 
                      (DrawY <  75);
    
    logic [8:0] x_frame_start;
    logic [6:0] sprite_w;
    logic [9:0] y_frame_start;
    
    always_comb begin
        x_frame_start = 0;
        sprite_w = 42;
        y_frame_start = 0;
        
        case(p1_state)
            //IDLE
            4'd0: begin
                y_frame_start = 0;
                case(p1_frame)
                    4'd0: begin
                        x_frame_start = 2;
                        sprite_w = 32;
                    end
                    4'd1: begin
                        x_frame_start = 37;
                        sprite_w = 31;
                    end
                    4'd2: begin
                        x_frame_start = 72;
                        sprite_w = 31;
                    end
                    4'd3: begin
                        x_frame_start = 107;
                        sprite_w = 29;
                    end
                endcase
            end
            //RIGHT
            4'd1: begin
                y_frame_start = 51;
                case(p1_frame)
                    4'd0: begin
                        x_frame_start = 11;
                        sprite_w = 32;
                    end
                    4'd1: begin
                        x_frame_start = 52;
                        sprite_w = 34;
                    end
                    4'd2: begin
                        x_frame_start = 90;
                        sprite_w = 33;
                    end
                    4'd3: begin
                        x_frame_start = 138;
                        sprite_w = 28;
                    end
                    4'd4: begin
                        x_frame_start = 182;
                        sprite_w = 27;
                    end

                endcase
            end
            //LEFT
            4'd2: begin
                y_frame_start = 102;
                case(p1_frame)
                    4'd0: begin
                        x_frame_start = 2;
                        sprite_w = 32;
                    end
                    4'd1: begin
                        x_frame_start = 47;
                        sprite_w = 31;
                    end
                    4'd2: begin
                        x_frame_start = 90;
                        sprite_w = 32;
                    end
                    4'd3: begin
                        x_frame_start = 134;
                        sprite_w = 30;
                    end
                    4'd4: begin
                        x_frame_start = 175;
                        sprite_w = 31;
                    end
                    4'd5: begin
                        x_frame_start = 219;
                        sprite_w = 30;
                    end
                endcase
            end
            //CROUCH
            4'd3: begin 
                y_frame_start = 153;
                case(p1_frame)
                    4'd0: begin
                        x_frame_start = 11;
                        sprite_w = 27;
                    end
                    4'd1: begin
                        x_frame_start = 47;
                        sprite_w = 33;
                    end
                    4'd2: begin
                        x_frame_start = 90;
                        sprite_w = 32;
                    end
                endcase
            end
            //JUMP
            4'd4: begin
                y_frame_start = 204;
                case(p1_frame)
                    4'd0: begin
                        x_frame_start = 3;
                        sprite_w = 26;
                    end
                    4'd1: begin
                        x_frame_start = 33;
                        sprite_w = 26;
                    end
                    4'd2: begin
                        x_frame_start = 64;
                        sprite_w = 24;
                    end
                    4'd3: begin
                        x_frame_start = 95;
                        sprite_w = 24;
                    end
                    4'd4: begin
                        x_frame_start = 119;
                        sprite_w = 22;
                    end
                    4'd5: begin
                        x_frame_start = 152;
                        sprite_w = 25;
                    end
                endcase
            end
            //PUNCH
            4'd5: begin
                y_frame_start = 255;
                case(p1_frame)
                    4'd0: begin
                        x_frame_start = 25;
                        sprite_w = 32;
                    end
                    4'd1: begin
                        x_frame_start = 69;
                        sprite_w = 48;
                    end
                endcase
            end
            //KICK
            4'd6: begin
                y_frame_start = 306;
                case(p1_frame)
                    4'd0: begin
                        x_frame_start = 23;
                        sprite_w = 34;
                    end
                    4'd1: begin
                        x_frame_start = 77;
                        sprite_w = 61;
                    end
                endcase
            end
            4'd7: begin
                y_frame_start = 357;
                case(p1_frame)
                    4'd0: begin
                        x_frame_start = 0;
                        sprite_w = 34;
                    end
                    4'd1: begin
                        x_frame_start = 54;
                        sprite_w = 35;
                    end
                    4'd2: begin
                        x_frame_start = 105; 
                        sprite_w = 38;
                    end
                    4'd3: begin
                        x_frame_start = 155; 
                        sprite_w = 43;
                    end
                endcase
            end
            4'd8: begin
                y_frame_start = 408;
                case(p1_frame)
                    4'd0: begin
                        x_frame_start = 0;
                        sprite_w = 40;
                    end
                    4'd1: begin
                        x_frame_start = 53;
                        sprite_w = 65;
                    end
                    4'd2: begin
                        x_frame_start = 120;
                        sprite_w = 62;
                    end
                    4'd3: begin
                        x_frame_start = 187;
                        sprite_w = 63;
                    end
                    4'd4: begin
                        x_frame_start = 251;
                        sprite_w = 64;
                    end
                endcase
            end
            4'd9: begin
                y_frame_start = 442;
                case(p1_frame)
                    4'd0: begin
                        x_frame_start = 1;
                        sprite_w = 33;
                    end
                    4'd1: begin
                        x_frame_start = 48;
                        sprite_w = 33;
                    end
                    4'd2: begin
                        x_frame_start = 73;
                        sprite_w = 29;
                    end
                endcase
            end
            default: begin
                x_frame_start = 2;
                y_frame_start = 0;
                sprite_w = 40;
            end
        endcase
    end
    
    
    logic [8:0] p2_x_frame_start;
    logic [6:0] p2_sprite_w;
    logic [9:0] p2_y_frame_start;
    
    
    always_comb begin
        p2_x_frame_start = 0;
        p2_sprite_w = 40;
        p2_y_frame_start = 0;
        
        case(p2_state)
            //IDLE
            4'd0: begin
                p2_y_frame_start = 0;
                case(p2_frame)
                    4'd0: begin
                        p2_x_frame_start = 0;
                        p2_sprite_w = 33;
                    end
                    4'd1: begin
                        p2_x_frame_start = 34;
                        p2_sprite_w = 31;
                    end
                    4'd2: begin
                        p2_x_frame_start = 68;
                        p2_sprite_w = 31;
                    end
                    4'd3: begin
                        p2_x_frame_start = 104;
                        p2_sprite_w = 28;
                    end
                endcase
            end
            //RIGHT
            4'd1: begin
                p2_y_frame_start = 51;
                case(p2_frame)
                    4'd0: begin
                        p2_x_frame_start = 9;
                        p2_sprite_w = 33;
                    end
                    4'd1: begin
                        p2_x_frame_start = 51;
                        p2_sprite_w = 36;
                    end
                    4'd2: begin
                        p2_x_frame_start = 91;
                        p2_sprite_w = 35;
                    end
                    4'd3: begin
                        p2_x_frame_start = 139;
                        p2_sprite_w = 31;
                    end
                    4'd4: begin
                        p2_x_frame_start = 186;
                        p2_sprite_w = 28;
                    end
                endcase
            end
            //LEFT
            4'd2: begin
                p2_y_frame_start = 102;
                case(p2_frame)
                    4'd0: begin
                        p2_x_frame_start = 1;
                        p2_sprite_w = 33;
                    end
                    4'd1: begin
                        p2_x_frame_start = 46;
                        p2_sprite_w = 32;
                    end
                    4'd2: begin
                        p2_x_frame_start = 89;
                        p2_sprite_w = 32;
                    end
                    4'd3: begin
                        p2_x_frame_start = 133;
                        p2_sprite_w = 31;
                    end
                    4'd4: begin
                        p2_x_frame_start = 175;
                        p2_sprite_w = 31;
                    end
                    4'd5: begin
                        p2_x_frame_start = 218;
                        p2_sprite_w = 31;
                    end
                endcase
            end
            //CROUCH
            4'd3: begin 
                p2_y_frame_start = 153;
                case(p2_frame)
                    4'd0: begin
                        p2_x_frame_start = 9;
                        p2_sprite_w = 30;
                    end
                    4'd1: begin
                        p2_x_frame_start = 46;
                        p2_sprite_w = 34;
                    end
                    4'd2: begin
                        p2_x_frame_start = 89;
                        p2_sprite_w = 33;
                    end
                endcase
            end
            //JUMP
            4'd4: begin
                p2_y_frame_start = 204;
                case(p2_frame)
                    4'd0: begin
                        p2_x_frame_start = 1;
                        p2_sprite_w = 27;
                    end
                    4'd1: begin
                        p2_x_frame_start = 32;
                        p2_sprite_w = 24;
                    end
                    4'd2: begin
                        p2_x_frame_start = 63;
                        p2_sprite_w = 25;
                    end
                    4'd3: begin
                        p2_x_frame_start = 96;
                        p2_sprite_w = 23;
                    end
                    4'd4: begin
                        p2_x_frame_start = 123;
                        p2_sprite_w = 23;
                    end
                    4'd5: begin
                        p2_x_frame_start = 154;
                        p2_sprite_w = 25;
                    end
                endcase
            end
            //PUNCH
            4'd5: begin
                p2_y_frame_start = 255;
                case(p2_frame)
                    4'd0: begin
                        p2_x_frame_start = 18;
                        p2_sprite_w = 40;
                    end
                    4'd1: begin
                        p2_x_frame_start = 70;
                        p2_sprite_w = 49;
                    end
                endcase
            end
            //KICK
            4'd6: begin
                p2_y_frame_start = 306;
                case(p2_frame)
                    4'd0: begin
                        p2_x_frame_start = 24;
                        p2_sprite_w = 34;
                    end
                    4'd1: begin
                        p2_x_frame_start = 78;
                        p2_sprite_w = 60;
                    end
                endcase
            end
            4'd7: begin
                p2_y_frame_start = 357;
                case(p2_frame)
                    4'd0: begin
                        p2_x_frame_start = 3;
                        p2_sprite_w = 32;
                    end
                    4'd1: begin
                        p2_x_frame_start = 57;
                        p2_sprite_w = 35;
                    end
                    4'd2: begin
                        p2_x_frame_start = 107;
                        p2_sprite_w = 43;
                    end
                    4'd3: begin
                        p2_x_frame_start = 162; 
                        p2_sprite_w = 44;
                    end
                endcase
            end
            4'd8: begin
                p2_y_frame_start = 408;
                case(p2_frame)
                    4'd0: begin
                        p2_x_frame_start = 1;
                        p2_sprite_w = 44;
                    end
                    4'd1: begin
                        p2_x_frame_start = 64;
                        p2_sprite_w = 71;
                    end
                    4'd2: begin
                        p2_x_frame_start = 137;
                        p2_sprite_w = 68;
                    end
                    4'd3: begin
                        p2_x_frame_start = 212;
                        p2_sprite_w = 70;
                    end
                    4'd4: begin
                        p2_x_frame_start = 284;
                        p2_sprite_w = 71;
                    end
                endcase
            end
            4'd9: begin
                p2_y_frame_start = 455;
                case(p2_frame)
                    4'd0: begin
                        p2_x_frame_start = 2;
                        p2_sprite_w = 31;
                    end
                    4'd1: begin
                        p2_x_frame_start = 35;
                        p2_sprite_w = 32;
                    end
                    4'd2: begin
                        p2_x_frame_start = 68;
                        p2_sprite_w = 29;
                    end
                endcase
            end
            default: begin
                p2_x_frame_start = 0;
                p2_y_frame_start = 0;
                p2_sprite_w = 40;
            end
        endcase
    end
    
    logic [9:0] p1_local_x, p2_local_x;
    assign p1_local_x = (DrawX - p1_x) >> 1;
    assign p2_local_x = (DrawX - p2_x) >> 1;
    
    logic [7:0] p1_local_x_clamped, p2_local_x_clamped;
    assign p1_local_x_clamped = (p1_local_x >= sprite_w)    ? sprite_w - 1    : p1_local_x[7:0];
    assign p2_local_x_clamped = (p2_local_x >= p2_sprite_w) ? p2_sprite_w - 1 : p2_local_x[7:0];
    
    logic [9:0] p1_sample_x, p2_sample_x;
    assign p1_sample_x = p1_flip ? (sprite_w    - 1 - p1_local_x_clamped) : p1_local_x_clamped;
    assign p2_sample_x = p2_flip ? (p2_sprite_w - 1 - p2_local_x_clamped) : p2_local_x_clamped;

    
    logic [9:0] p1_sprite_h, p2_sprite_h;

    always_comb begin
        case (p1_state)
            KO_ANIM:  p1_sprite_h = P1_KO_H;
            WIN_ANIM: p1_sprite_h = P1_WIN_H;
            default:  p1_sprite_h = SPRITE_H;
        endcase
    end
    
    always_comb begin
        case (p2_state)
            KO_ANIM:  p2_sprite_h = P2_KO_H;
            WIN_ANIM: p2_sprite_h = P2_WIN_H;
            default:  p2_sprite_h = SPRITE_H;
        endcase
    end
    
    logic [9:0] p1_draw_y, p2_draw_y;

    always_comb begin
        case (p1_state)
            KO_ANIM:  p1_draw_y = p1_y + (SPRITE_H - P1_KO_H) * SCALE;   // +34
            WIN_ANIM: p1_draw_y = (p1_y >= (P1_WIN_H - SPRITE_H) * SCALE)
                                  ? p1_y - (P1_WIN_H - SPRITE_H) * SCALE  // -32
                                  : 10'd0;
            default:  p1_draw_y = p1_y;
        endcase
    end

    always_comb begin
        case (p2_state)
            KO_ANIM:  p2_draw_y = p2_y + (SPRITE_H - P2_KO_H) * SCALE;   // +8
            WIN_ANIM: p2_draw_y = (p2_y >= (P2_WIN_H - SPRITE_H) * SCALE)
                                  ? p2_y - (P2_WIN_H - SPRITE_H) * SCALE  // -28
                                  : 10'd0;
            default:  p2_draw_y = p2_y;
        endcase
    end
    
    logic [17:0] p1_rom_address;
    logic [3:0] p1_rom_q;
    logic [3:0] p1_red, p1_green, p1_blue;
    logic p1_active, p1_active_d;
    
    logic [17:0] p2_rom_address;
    logic [3:0]  p2_rom_q;
    logic [3:0]  p2_red, p2_green, p2_blue;
    logic        p2_active, p2_active_d;
    
    logic [3:0] ko_red, ko_green, ko_blue;
    logic [3:0] ko_q;
    logic [17:0] ko_addr;
    logic ko_active;
    
    logic p1_flip, p2_flip;
    
    logic [3:0] bg_red, bg_green, bg_blue;
    logic [3:0] bg_red_d, bg_green_d, bg_blue_d;
    logic [9:0] cameraX;
    logic [18:0] bg_address;
    logic [3:0] bg_q;
    logic [9:0] bgX, bgY;
    logic negedge_vga_clk;
    
    // read from ROM on negedge, set pixel on posedge
    assign negedge_vga_clk = ~vga_clk;
    
    assign p1_active = (DrawX >= p1_x) &&
                       (DrawX <  p1_x + sprite_w * SCALE) &&
                       (DrawY >= p1_draw_y) &&
                       (DrawY <  p1_draw_y + p1_sprite_h * SCALE);
    
    
    assign p1_rom_address = (y_frame_start * P1_IMG_W) + x_frame_start + p1_sample_x
                            + (((DrawY - p1_draw_y) >> 1) * P1_IMG_W);
    
    
    assign p2_active = (DrawX >= p2_x) &&
                       (DrawX <  p2_x + p2_sprite_w * SCALE) &&
                       (DrawY >= p2_draw_y) &&
                       (DrawY <  p2_draw_y + p2_sprite_h * SCALE);
    
    
    assign p2_rom_address = (p2_y_frame_start * P2_IMG_W) + p2_x_frame_start + p2_sample_x
                             + (((DrawY - p2_draw_y) >> 1) * P2_IMG_W);
    
    assign p1_flip = (p1_x < p2_x);  // flip when P1 is on the left
    assign p2_flip = (p2_x < p1_x);  // flip when P2 is on the right
    
    
    assign ko_active = ko_flag && (DrawX >= KO_X) && (DrawX < KO_X + KO_W*2) && (DrawY >= KO_Y) && (DrawY < KO_Y + KO_H*2);
    
    logic [9:0] ko_local_x = (DrawX - KO_X) >> 1;
    logic [9:0] ko_local_y = (DrawY - KO_Y) >> 1;
    
    assign ko_addr = ko_local_y * KO_SHEET_W + ko_local_x;    
    
    
    logic [16:0] title_addr;
    logic [3:0]  title_q;
    logic [3:0]  title_red, title_green, title_blue;
    logic        title_active_d;
    
    
    assign title_addr = ((DrawY >> 1) * 320) + (DrawX >> 1);
    
    
//    logic [5:0]  flash_counter;
//    logic        flash_visible;
//    logic        frame_start;
    
//    assign frame_start = (DrawX == 0) && (DrawY == 0);
    
//    always_ff @(posedge vga_clk) begin
//        if (!title_screen)
//            flash_counter <= 0;
//        else if (frame_start) begin
//            if (flash_counter == 6'd59)
//                flash_counter <= 0;
//            else
//                flash_counter <= flash_counter + 1;
//        end
//    end
    
//    assign flash_visible = (flash_counter < 30);
    
//    logic press_key_active;
//    assign press_key_active = title_screen &&
//                              flash_visible &&
//                              (DrawY >= 380) && (DrawY < 410) &&
//                              (DrawX >= 160) && (DrawX < 480);
    
    logic [10:0] midpoint; 
    logic [9:0]  midpoint_clamped;
    
    assign midpoint = ({1'b0, p1_x} + {1'b0, p2_x}) >> 1;
    
    // Prevent midpoint from ever jumping outside valid camera range
    assign midpoint_clamped =
        (midpoint < (SCREEN_W >> 1)) ? (SCREEN_W >> 1) :
        (midpoint > (BG_W - (SCREEN_W >> 1))) ? (BG_W - (SCREEN_W >> 1)) :
        midpoint; 
    
    logic signed [10:0] cameraX_next;
    logic signed [10:0] cameraX_s;
    
    assign cameraX_s = cameraX;
    assign cameraX_next = midpoint_clamped - (SCREEN_W >> 1);
    
    always_ff @(posedge vga_clk) begin
        if (DrawX == 0 && DrawY == 0) begin
            if (cameraX_s < cameraX_next)
                cameraX <= cameraX + 1; // Note: Moving 1px per frame is 60px/second. 
            else if (cameraX_s > cameraX_next)
                cameraX <= cameraX - 1; // If this pans too slowly, you can increase the step size!
        end
    end
    
    // 2. MATH FIX: Add DrawX and cameraX FIRST, then scale down by 4
    assign bgX = ((DrawX + cameraX) >> 2) & 8'hFF;
    assign bgY = DrawY >> 2; 
    assign bg_address = (bgY << 8) + bgX;
    
    bg_stage bg_stage (
        .clka  (negedge_vga_clk),
        .ena   (1'b1),
        .addra (bg_address),
        .douta (bg_q)
    );
    
    street_fighter_bg_palette bg_palette (
        .index (bg_q),
        .red   (bg_red),
        .green (bg_green),
        .blue  (bg_blue)
    );

    ryu_animations p1_rom (
        .clka  (negedge_vga_clk),
        .ena   (p1_active),
        .addra (p1_rom_address),
        .douta (p1_rom_q)
    );
    
    ryu_animations_palette ryu_animations_palette (
        .index (p1_rom_q),
        .red   (p1_red),
        .green (p1_green),
        .blue  (p1_blue)
    );
    
    ken_animations p2_rom(
        .clka   (negedge_vga_clk),
        .ena    (p2_active),
        .addra  (p2_rom_address),
        .douta  (p2_rom_q)
    );
    
    ken_sprite_sheet_palette ken_animations_palette (
        .index  (p2_rom_q),
        .red    (p2_red),
        .green  (p2_green),
        .blue   (p2_blue)
    );
    
   
    
    ko_image ko_sprite (
        .clka   (negedge_vga_clk),
        .ena    (ko_active),
        .addra  (ko_addr),
        .douta  (ko_q)
    );
    
    ko_image_palette ko_sprite_palette (
        .index  (ko_q),
        .red    (ko_red),
        .green  (ko_green),
        .blue   (ko_blue)
    );
    
    
    title_screen title_rom (
        .clka  (negedge_vga_clk),
        .ena   (title_screen),
        .addra (title_addr),
        .douta (title_q)
    );
    
    sf2_title_palette sf2_title_palette (
        .index (title_q),
        .red   (title_red),
        .green (title_green),
        .blue  (title_blue)
    );
    
    
    always_ff @(posedge vga_clk) begin
        p1_active_d <= p1_active;
        p2_active_d <= p2_active;
        bg_red_d   <= bg_red;
        title_active_d <= title_screen;
        bg_green_d <= bg_green;
        bg_blue_d  <= bg_blue;
    end
    
    always_comb begin
        // background gradient
        Red   = bg_red_d;
        Green = bg_green_d;
        Blue  = bg_blue_d;
        if (title_active_d) begin
        // Title screen takes over the whole display
            Red   = title_red;
            Green = title_green;
            Blue  = title_blue;

            // Flashing text overlay (solid white bar - or bake text into art instead)
//            if (press_key_active) begin
//                Red   = 4'hF;
//                Green = 4'hF;
//                Blue  = 4'hF;
//            end
        end else begin
            if (p1_hp_border) begin
                Red = 4'hF;
                Green = 4'hF;
                Blue = 4'hF;
            end
            
            if (p2_hp_border) begin
                Red = 4'hF;
                Green = 4'hF;
                Blue = 4'hF;
            end
            
            if (p1_hp_bg) begin
                Red = 4'hF;
                Green = 4'h0;
                Blue = 4'h0;
            end
            
            if (p2_hp_bg) begin
                Red = 4'hF;
                Green = 4'h0;
                Blue = 4'h0;
            end
            
            if (ko_ui_active) begin
                Red = 4'hF;
                Green = 4'h0;
                Blue = 4'h0;
            end
            
            if (p1_hp_active) begin
                Red = 4'hF;
                Green = 4'hF;
                Blue = 4'h0;
            end
            
            if (p2_hp_active) begin
                Red = 4'hF;
                Green = 4'hF;
                Blue = 4'h0;
            end
            
            if (p2_active_d && p2_rom_q != 4'h0 && p2_active_d && p2_rom_q != 4'h6 && p2_active_d && p2_rom_q != 4'h7) begin
                Red   = p2_red;
                Green = p2_green;
                Blue  = p2_blue;
            end
            
            if (p1_active_d && p1_rom_q != 4'h0 && p1_active_d && p1_rom_q != 4'h6 && p1_active_d && p1_rom_q != 4'hB) begin
                Red   = p1_red;
                Green = p1_green;
                Blue  = p1_blue;
            end
            
            if (ko_active && ko_q != 4'h0) begin
                Red   = ko_red;
                Green = ko_green;
                Blue  = ko_blue;
            end
    
        end
    end
    

endmodule
