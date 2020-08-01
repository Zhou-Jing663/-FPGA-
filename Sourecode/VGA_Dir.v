`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/07/27 13:33:47
// Design Name: 
// Module Name: VGA_Dir
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

//????
module VGA_Dir(
    input clk,
    input [11:0] data_in,
    output [11:0] data_out,  //数据输出
    output wire hsync,
    output wire vsync
    );
    
    reg [9:0] hcount = 0;
    reg [9:0] vcount = 0;
    wire hcount_ov ;
    wire vcount_ov ;
    reg vga_clk = 0;
    reg cnt_clk = 0;
    wire dat_act;
    
    parameter hsync_end = 10'd95,
               hdat_begin= 10'd143,
               hdat_end  = 10'd783,
               hpixel_end= 10'd799,
               vsync_end = 10'd1,
               vdat_begin= 10'd34,
               vdat_end  = 10'd514,
               vline_end = 10'd524;
   // parameter data_in = 12'b1111_0000_0000;
    //分频
    always @ (posedge clk)
    begin
        if(cnt_clk == 1) begin
            vga_clk <= ~vga_clk;
            cnt_clk <= 0;
            end
        else begin
            cnt_clk <= cnt_clk + 1;
            end
    end 
    
    always @ (posedge vga_clk)
    begin   
        if(hcount_ov)
            hcount <= 10'd0 ;
        else
            hcount <= hcount + 10'd1 ;
    end
    assign hcount_ov = ( hcount == hpixel_end ) ;
    
    always @ (posedge vga_clk)
    begin
        if(hcount_ov) begin
            if(vcount_ov)
               vcount <= 10'd0 ;
            else
                vcount <= vcount + 10'd1 ;
            end
        end
    assign vcount_ov = ( vcount == vline_end ) ;
    
    assign dat_act = (( hcount >= hdat_begin ) && ( hcount < hdat_end )) && (( vcount >= vdat_begin ) && (vcount < vdat_end ));
    assign data_out = (dat_act)? data_in : 12'h000;
    assign hsync = ( hcount > hsync_end );
    assign vsync = ( vcount > vsync_end );
    
endmodule
