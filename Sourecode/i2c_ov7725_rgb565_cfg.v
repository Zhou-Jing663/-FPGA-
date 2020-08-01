//该程序使用正点原子的驱动程序，本剧自己的需求稍加修改
module i2c_ov7725_rgb565_cfg(  
    input                clk      ,  
    input                rst_n    ,  
    input                i2c_done,
    output  reg          i2c_exec ,    
    output  reg  [15:0]  i2c_data ,  
    output  reg          init_done   
    );

parameter  REG_NUM = 7'd42   ;       
reg [9:0] start_init_cnt;
reg [6:0] init_reg_cnt;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        start_init_cnt <= 10'b0;    
    else if((init_reg_cnt == 7'd1) && i2c_done)
        start_init_cnt <= 10'b0;
    else if(start_init_cnt < 10'd1023) begin
        start_init_cnt <= start_init_cnt + 1'b1;                    
    end
end
    
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        init_reg_cnt <= 7'd0;
    else if(i2c_exec)   
        init_reg_cnt <= init_reg_cnt + 7'b1;
end         
 
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        i2c_exec <= 1'b0;
    else if(start_init_cnt == 10'd1022)
        i2c_exec <= 1'b1;
    else if(i2c_done && (init_reg_cnt != 7'd1) && (init_reg_cnt < REG_NUM))
        i2c_exec <= 1'b1;
    else
        i2c_exec <= 1'b0;    
end 

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        init_done <= 1'b0;
    else if((init_reg_cnt == REG_NUM) && i2c_done)  
        init_done <= 1'b1;  
end        
   
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        i2c_data <= 16'b0;
    else begin
        case(init_reg_cnt)
            7'd0  : i2c_data <= {8'h12, 8'h80}; 
            7'd1  : i2c_data <= {8'h3d, 8'h03}; 
            7'd2  : i2c_data <= {8'h15, 8'h00}; 
            7'd3  : i2c_data <= {8'h17, 8'h26}; 
            7'd4  : i2c_data <= {8'h18, 8'ha0}; 
            7'd5  : i2c_data <= {8'h19, 8'h07}; 
            7'd6  : i2c_data <= {8'h1a, 8'hf0};           
            7'd7  : i2c_data <= {8'h32, 8'h00};
            7'd8  : i2c_data <= {8'h29, 8'ha0}; 
            7'd9  : i2c_data <= {8'h2a, 8'h00}; 
            7'd10 : i2c_data <= {8'h2b, 8'h00}; 
            7'd11 : i2c_data <= {8'h2c, 8'hf0}; 
            7'd12 : i2c_data <= {8'h0d, 8'h41}; 
            7'd13 : i2c_data <= {8'h11, 8'h00}; 
            7'd14 : i2c_data <= {8'h12, 8'h06};
            7'd15 : i2c_data <= {8'h0c, 8'h10}; 
            7'd16 : i2c_data <= {8'h42, 8'h7f}; 
            7'd17 : i2c_data <= {8'h4d, 8'h09}; 
            7'd18 : i2c_data <= {8'h63, 8'hf0}; 
            7'd19 : i2c_data <= {8'h64, 8'hff};
            7'd20 : i2c_data <= {8'h65, 8'h00}; 
            7'd21 : i2c_data <= {8'h66, 8'h00};
            7'd22 : i2c_data <= {8'h67, 8'h00}; 
            7'd23 : i2c_data <= {8'h13, 8'hff}; 
            7'd24 : i2c_data <= {8'h0f, 8'hc5}; 
            7'd25 : i2c_data <= {8'h14, 8'h11};  
            7'd26 : i2c_data <= {8'h22, 8'h98}; 
            7'd27 : i2c_data <= {8'h23, 8'h03};  
            7'd28 : i2c_data <= {8'h24, 8'h40}; 
            7'd29 : i2c_data <= {8'h25, 8'h30};  
            7'd30: i2c_data <= {8'h26, 8'ha1};      
            7'd31: i2c_data <= {8'h6b, 8'haa}; 
            7'd32: i2c_data <= {8'h13, 8'hff};  
            7'd33 : i2c_data <= {8'h90, 8'h0a};
            7'd34 : i2c_data <= {8'h91, 8'h01}; 
            7'd35 : i2c_data <= {8'h92, 8'h01}; 
            7'd36 : i2c_data <= {8'h93, 8'h01}; 
            7'd37 : i2c_data <= {8'h94, 8'h5f}; 
            7'd38 : i2c_data <= {8'h95, 8'h53}; 
            7'd39 : i2c_data <= {8'h96, 8'h11}; 
            7'd40 : i2c_data <= {8'h97, 8'h1a}; 
            7'd41 : i2c_data <= {8'h98, 8'h3d}; 
            7'd42 : i2c_data <= {8'h99, 8'h5a}; 
            7'd43 : i2c_data <= {8'h9a, 8'h1e}; 
            7'd44 : i2c_data <= {8'h9b, 8'h3f}; 
            7'd45 : i2c_data <= {8'h9c, 8'h25};            
            7'd46 : i2c_data <= {8'h9e, 8'h81}; 
            7'd47 : i2c_data <= {8'ha6, 8'h06}; 
            7'd48 : i2c_data <= {8'ha7, 8'h65}; 
            7'd49 : i2c_data <= {8'ha8, 8'h65};            
            7'd50 : i2c_data <= {8'ha9, 8'h80};   
            7'd51 : i2c_data <= {8'haa, 8'h80}; 
            7'd52 : i2c_data <= {8'h7e, 8'h0c}; 
            7'd53 : i2c_data <= {8'h7f, 8'h16}; 
            7'd54 : i2c_data <= {8'h80, 8'h2a}; 
            7'd55 : i2c_data <= {8'h81, 8'h4e}; 
            7'd56 : i2c_data <= {8'h82, 8'h61}; 
            7'd57 : i2c_data <= {8'h83, 8'h6f}; 
            7'd58 : i2c_data <= {8'h84, 8'h7b}; 
            7'd59 : i2c_data <= {8'h85, 8'h86};   
            7'd60 : i2c_data <= {8'h86, 8'h8e}; 
            7'd61 : i2c_data <= {8'h87, 8'h97}; 
            7'd62 : i2c_data <= {8'h88, 8'ha4}; 
            7'd63 : i2c_data <= {8'h89, 8'haf}; 
            7'd64 : i2c_data <= {8'h8a, 8'hc5}; 
            7'd65 : i2c_data <= {8'h8b, 8'hd7}; 
            7'd66 : i2c_data <= {8'h8c, 8'he8}; 
            7'd67 : i2c_data <= {8'h8d, 8'h20};
            7'd68 : i2c_data <= {8'h0e, 8'h65}; 
            7'd69 : i2c_data <= {8'h09, 8'h00};
            default:i2c_data <=	{8'h1C, 8'h7F};
        endcase
    end
end

endmodule