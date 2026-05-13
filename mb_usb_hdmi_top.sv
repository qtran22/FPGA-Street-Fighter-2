//-------------------------------------------------------------------------
//    mb_usb_hdmi_top.sv                                                 --
//    Zuofu Cheng                                                        --
//    2-29-24                                                            --
//    10-14-25                                                           --
//                                                                       --
//    Fall 2025 Distribution                                           --
//                                                                       --
//    For use with ECE 385 USB + HDMI                                    --
//    University of Illinois ECE Department                              --
//-------------------------------------------------------------------------


module mb_usb_hdmi_top(
    input logic Clk,
    input logic reset_rtl_0,
    
    //USB signals
    input logic [0:0] gpio_usb_int_tri_i,
    output logic gpio_usb_rst_tri_o,
    input logic usb_spi_miso,
    output logic usb_spi_mosi,
    output logic usb_spi_sclk,
    output logic usb_spi_ss,
    
    //UART
    input logic uart_rtl_0_rxd,
    output logic uart_rtl_0_txd,
    
    //HDMI
    output logic hdmi_tmds_clk_n,
    output logic hdmi_tmds_clk_p,
    output logic [2:0]hdmi_tmds_data_n,
    output logic [2:0]hdmi_tmds_data_p,
        
    //HEX displays
    output logic [7:0] hex_segA,
    output logic [3:0] hex_gridA,
    output logic [7:0] hex_segB,
    output logic [3:0] hex_gridB
);
    
    logic [31:0] keycode0_gpio, keycode1_gpio;
    logic clk_25MHz, clk_125MHz, clk, clk_100MHz;
    logic locked;
    logic [9:0] drawX, drawY, p1_x, p1_y, p2_x, p2_y;
    logic [15:0] p1_hp, p2_hp;
    logic p1_hit, p2_hit;
    logic p1_ko, p2_ko;

    logic hsync, vsync, vde;
    logic [3:0] red, green, blue;
    logic reset_ah;
    
    logic [3:0] p1_state;
    logic [3:0] p1_frame;
    logic [3:0] p2_state;
    logic [3:0] p2_frame;
    
    logic ko_flag;
    assign ko_flag = (p1_hp == 0) || (p2_hp == 0);
    

    
    assign reset_ah = reset_rtl_0;
        
    logic [31:0] combined_hp_to_c;
    assign combined_hp_to_c = {p1_hp, p2_hp};
    
    logic title_screen;
    logic enter_key, enter_key_prev, enter_key_pulse;
    
    assign enter_key = (keycode0_gpio[7:0]   == 8'h28) || 
                       (keycode0_gpio[15:8]  == 8'h28) || 
                       (keycode0_gpio[23:16] == 8'h28) || 
                       (keycode0_gpio[31:24] == 8'h28);
    
    always_ff @(posedge vsync or posedge reset_ah) begin
        if (reset_ah) enter_key_prev <= 0;
        else          enter_key_prev <= enter_key;
    end
    
    assign enter_key_pulse = enter_key & ~enter_key_prev;
    
    
    typedef enum logic { TITLE, GAME } game_state_t;
    game_state_t game_state;
    
    always_ff @(posedge vsync or posedge reset_ah) begin
        if (reset_ah) begin
            game_state <= TITLE;
        end else begin
            case (game_state)
                TITLE: if (enter_key_pulse)            game_state <= GAME;
                GAME:  if (ko_flag && enter_key_pulse) game_state <= TITLE;
            endcase
        end
    end
    
    assign title_screen = (game_state == TITLE);
    
    
    logic game_reset;
    logic prev_title_screen;
    
    always_ff @(posedge vsync or posedge reset_ah) begin
        if (reset_ah) prev_title_screen <= 1;
        else          prev_title_screen <= title_screen;
    end
    
    
    assign game_reset = prev_title_screen & ~title_screen;
    
    //Keycode HEX drivers
    hex_driver HexA (
        .clk(Clk),
        .reset(reset_ah),
        .in({keycode0_gpio[31:28], keycode0_gpio[27:24], keycode0_gpio[23:20], keycode0_gpio[19:16]}),
        .hex_seg(hex_segA),
        .hex_grid(hex_gridA)
    );
    
    hex_driver HexB (
        .clk(Clk),
        .reset(reset_ah),
        .in({keycode0_gpio[15:12], keycode0_gpio[11:8], keycode0_gpio[7:4], keycode0_gpio[3:0]}),
        .hex_seg(hex_segB),
        .hex_grid(hex_gridB)
    );
    
    
    mb_block mb_block_i (
        .clk_100MHz(Clk),
        .gpio_usb_int_tri_i(gpio_usb_int_tri_i),
        .gpio_usb_keycode_0_tri_o(keycode0_gpio),
        .gpio_usb_keycode_1_tri_o(keycode1_gpio),
        .gpio_usb_rst_tri_o(gpio_usb_rst_tri_o),
        .reset_rtl_0(~reset_ah), //Block designs expect active low reset, all other modules are active high
        .uart_rtl_0_rxd(uart_rtl_0_rxd),
        .uart_rtl_0_txd(uart_rtl_0_txd),
        .usb_spi_miso(usb_spi_miso),
        .usb_spi_mosi(usb_spi_mosi),
        .usb_spi_sclk(usb_spi_sclk),
        .usb_spi_ss(usb_spi_ss),
        
        .gpio_hitbox_tri_i(combined_hp_to_c)
       
    );
        
    //clock wizard configured with a 1x and 5x clock for HDMI
    clk_wiz_0 clk_wiz (
        .clk_out1(clk_25MHz),
        .clk_out2(clk_125MHz),
        .reset(reset_ah),
        .locked(locked),
        .clk_in1(Clk)
    );
    
    //VGA Sync signal generator
    vga_controller vga (
        .pixel_clk(clk_25MHz),
        .reset(reset_ah),
        .hs(hsync),
        .vs(vsync),
        .active_nblank(vde),
        .drawX(drawX),
        .drawY(drawY)
    );    

    //Real Digital VGA to HDMI converter
    hdmi_tx_0 vga_to_hdmi (
        //Clocking and Reset
        .pix_clk(clk_25MHz),
        .pix_clkx5(clk_125MHz),
        .pix_clk_locked(locked),
        .rst(reset_ah),
        //Color and Sync Signals
        .red(red),
        .green(green),
        .blue(blue),
        .hsync(hsync),
        .vsync(vsync),
        .vde(vde),
        
        //aux Data (unused)
        .aux0_din(4'b0),
        .aux1_din(4'b0),
        .aux2_din(4'b0),
        .ade(1'b0),
        
        //Differential outputs
        .TMDS_CLK_P(hdmi_tmds_clk_p),          
        .TMDS_CLK_N(hdmi_tmds_clk_n),          
        .TMDS_DATA_P(hdmi_tmds_data_p),         
        .TMDS_DATA_N(hdmi_tmds_data_n)          
    );
    

   
    
    //draw sprites   
    sprite_renderer renderer_instance(
        .vga_clk(clk_25MHz),
        .DrawX(drawX),
        .DrawY(drawY),
        .p1_x(p1_x),
        .p1_y(p1_y),
        .p1_state(p1_state),
        .p1_frame(p1_frame),
        .p1_hp(p1_hp),
        .p2_hp(p2_hp),
        .p2_x(p2_x),
        .p2_y(p2_y),
        .p2_state(p2_state),
        .p2_frame(p2_frame),
        .Red(red),
        .Green(green),
        .Blue(blue),
        .ko_flag(ko_flag),
        .title_screen(title_screen)
    );
    
    
    //player controls
    player1 player1_instance(
        .Reset(reset_ah | game_reset),
        .frame_clk(vsync),                    //Figure out what this should be so that the ball will move
        .keycode(keycode0_gpio),    //Notice: only one keycode connected to ball by default
        .posX(p1_x),
        .posY(p1_y),
        .state(p1_state),
        .frame_index(p1_frame),
        .got_hit(p1_hit),
        .p2_posX(p2_x),
        .am_ko(p1_ko),
        .opponent_ko(p2_ko)
    );
    
    player2 player2_instance(
        .Reset(reset_ah | game_reset),
        .frame_clk(vsync),                    //Figure out what this should be so that the ball will move
        .keycode(keycode0_gpio),    //Notice: only one keycode connected to ball by default
        .posX(p2_x),
        .posY(p2_y),
        .state(p2_state),
        .frame_index(p2_frame),
        .got_hit(p2_hit),
        .p1_posX(p1_x),
        .am_ko(p2_ko),
        .opponent_ko(p1_ko)
    );
    
    
    
    //hp bar logic
    health_bar hp_inst(
        .clk(vsync),
        .Reset(reset_ah | game_reset),
        .p1_hit(p1_hit),
        .p2_hit(p2_hit),
        .p1_damage(8'd10),
        .p2_damage(8'd10),
        .p1_hp(p1_hp),
        .p2_hp(p2_hp),
        .p1_ko(p1_ko),
        .p2_ko(p2_ko)
    );
    
    //hitbox logic
    hitbox hitbox_inst(
        .clk(vsync),
        .Reset(reset_ah | game_reset),
        .p1_x(p1_x),
        .p1_y(p1_y),
        .p1_state(p1_state),
        .p1_frame(p1_frame),
        .p2_x(p2_x),
        .p2_y(p2_y),
        .p2_state(p2_state),
        .p2_frame(p2_frame),
        .p1_hit(p1_hit),
        .p2_hit(p2_hit)
    );
    
endmodule
