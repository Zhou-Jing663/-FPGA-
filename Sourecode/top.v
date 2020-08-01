module ov7725_rgb565_640x480_vga(    
    input                 sys_clk     ,  //系统时钟
    input                 sys_rst_n   ,  //系统复位，低电平有效
    //摄像头接口
    input                 cam_pclk    ,  //cmos 数据像素时钟
    input                 cam_vsync   ,  //cmos 场同步信号
    input                 cam_href    ,  //cmos 行同步信号
    input        [7:0]    cam_data    ,  //cmos 数据
    output                cam_rst_n   ,  //cmos 复位信号，低电平有效
    output                cam_sgm_ctrl,  //cmos 时钟选择信号, 1:使用摄像头自带的晶振
    output                cam_scl     ,  //cmos SCCB_SCL线
    inout                 cam_sda     ,  //cmos SCCB_SDA线   
    //VGA接口                          
    output                vga_hs      ,  //行同步信号
    output                vga_vs      ,  //场同步信号
    output        [11:0]  vga_rgb     ,   //红绿蓝三原色输出 
    
    output led0,
    output led1,
    output led2,
    output led3
    );

//parameter define
parameter  SLAVE_ADDR =  7'h21        ;  //OV7725的器件地址7'h21
parameter  BIT_CTRL   =  1'b0         ;  //OV7725的字节地址为8位  0:8位 1:16位
parameter  CLK_FREQ   = 26'd25_000_000;  //i2c_dri模块的驱动时钟频率 25MHz
parameter  I2C_FREQ   = 18'd250_000   ;  //I2C的SCL时钟频率,不超过400KHz
parameter  CMOS_H_PIXEL = 24'd640     ;  //CMOS水平方向像素个数,用于设置SDRAM缓存大小
parameter  CMOS_V_PIXEL = 24'd480     ;  //CMOS垂直方向像素个数,用于设置SDRAM缓存大小

//wire define
reg                  clk_25m         ;  //25mhz时钟,提供给vga驱动时钟
reg                   count ;           //用于产生25MHz时钟
wire                  rst_n           ;
                                      
wire                  i2c_exec        ;  //I2C触发执行信号
wire   [15:0]         i2c_data        ;  //I2C要配置的地址与数据(高8位地址,低8位数据)          
wire                  cam_init_done   ;  //摄像头初始化完成
wire                  i2c_done        ;  //I2C寄存器配置完成信号
wire                  i2c_dri_clk     ;  //I2C操作时钟
                                      
wire                  wr_en           ;  //FIFO模块写使能
wire   [15:0]         wr_data         ;  //摄像头数据
wire                  rd_en           ;  //FIFO读使能
reg   [11:0]         rd_data         ;  //VGA读数据
wire                  sys_init_done   ;  //系统初始化完成(sdram初始化+摄像头初始化)
wire                  dout           ;  //FIFO输出
wire face_data1;
wire face_data2;
wire face_data3;
reg [18:0] addra;
reg [18:0] addrb;
reg wea1;
reg wea2;
reg wr_clk;
wire           cmos_frame_href; //摄像头hang有效的标志
wire cmos_frame_vsync;//zhen有效标志
reg cam_vsync_wire;
assign led0 = face_data1 ? 1'b1 : 1'b0;
assign  rst_n = sys_rst_n ;
//系统初始化完成：RAM和摄像头都初始化完成
assign  sys_init_done =   cam_init_done;
//不对摄像头硬件复位,固定高电平
assign  cam_rst_n = 1'b1;
//cmos 时钟选择信号,0:使用引脚XCLK提供的时钟 1:使用摄像头自带的晶振
assign  cam_sgm_ctrl = 1'b1;
//FIFO写时钟
always @ (posedge cam_pclk) begin
    if(!sys_rst_n)
        wr_clk <= 0 ;
    else
        wr_clk = ~wr_clk;
    end
//25MHz时钟
always @ (posedge sys_clk) begin
    if(!sys_rst_n) begin
        count <= 0;
        clk_25m <= 0 ;
        end
    else begin
        count <= ~count;
        if( count == 1 )
            clk_25m <= ~clk_25m ;
        end
    end
always @ (posedge cam_vsync) begin
        if(!sys_rst_n) begin
            wea1 <= 0;
            wea2 <= 1 ;
        end
        else begin
            wea1 <= ~wea1 ;
            wea2 <= ~wea2 ;
        end
end
always @ (posedge cam_pclk) begin
         if(!sys_rst_n ) begin
            addra <= 19'b0; end
         else if (cam_vsync)
            addra <= 19'b0;
         else if( cmos_frame_href ) begin
                if( addra < 19'd307200) begin
                      addra <= addra + 19'b1 ;
                      end
                end
         end
always @ (posedge clk_25m) begin
         if(!sys_rst_n | vga_vs) begin
            addrb <= 19'b0; end
         else if( rd_en ) begin
            if(addrb < 19'd307200)
                addrb <= addrb + 19'b1 ;
            end
         end   
always @ (posedge  sys_clk) begin
    if(!sys_rst_n ) begin
        rd_data <= 12'h00f; end
    else if(!wea1) begin
        if(face_data2)
            rd_data <= 12'hf00;
        else
            rd_data <= 12'h0f0;
        end
    else if(!wea2) begin
        if(face_data3)
            rd_data <= 12'hf00;
        else
            rd_data <= 12'h0f0;
        end     
end   
ila_0 ila(
    .clk(sys_clk),
    .probe0(face_data1),
    .probe1(face_data2)
);     
RAM_pingpang pingpang1(
    .addra(addra),
    .dina(face_data1),
    .clka(cam_pclk),
    .ena(1'b1),
    .wea(wea1),
    .addrb(addrb),
    .doutb(face_data2),
    .clkb(clk_25m),
    .enb(1'b1)
);
RAM_pingpang pingpang2(
    .addra(addra),
    .dina(face_data1),
    .clka(cam_pclk),
    .ena(1'b1),
    .wea(wea2),
    .addrb(addrb),
    .doutb(face_data3),
    .clkb(clk_25m),
    .enb(1'b1)
);
//CMOS图像数据采集模块
cmos_capture_data u_cmos_capture_data(
    .rst_n              (rst_n & sys_init_done),    //系统初始化完成之后再开始采集数据
   
    .cam_pclk           (cam_pclk),
    .cam_vsync          (cam_vsync),
    .cam_href           (cam_href),
    .cam_data           (cam_data),   
   
    .cmos_frame_vsync   (cmos_frame_vsync),
    .cmos_frame_href    (cmos_frame_href),       //行有效信息
    .cmos_frame_valid   (wr_en),                    //数据有效使能信号
    .cmos_frame_data    (wr_data)                  //有效数据 
    );	
//VGA驱动模块
vga_driver u_vga_driver(
    .vga_clk            (clk_25m),    
    .sys_rst_n          (rst_n),  
    .vga_hs             (vga_hs),       
    .vga_vs             (vga_vs),       
    .vga_rgb            (vga_rgb),      
        
    .pixel_data         (rd_data), 
    .data_req           (rd_en),                    //请求像素点颜色数据输入
    .pixel_xpos         (), 
    .pixel_ypos         ()
    ); 
//I2C配置模块    
i2c_ov7725_rgb565_cfg u_i2c_cfg(
    .clk                (i2c_dri_clk),
    .rst_n              (rst_n),
            
    .i2c_done           (i2c_done),
    .i2c_exec           (i2c_exec),
    .i2c_data           (i2c_data),
    .init_done          (cam_init_done)
    );    

//I2C驱动模块
i2c_dri 
   #(
    .SLAVE_ADDR         (SLAVE_ADDR),
    .CLK_FREQ           (CLK_FREQ  ),              
    .I2C_FREQ           (I2C_FREQ  )                
    )       
   u_i2c_dri(       
    .clk                (clk_25m   ),   
    .rst_n              (rst_n     ),   
        
    .i2c_exec           (i2c_exec  ),   
    .bit_ctrl           (BIT_CTRL  ),   
    .i2c_rh_wl          (1'b0),                     //固定为0，只用到了IIC驱动的写操作   
    .i2c_addr           (i2c_data[15:8]),   
    .i2c_data_w         (i2c_data[7:0]),   
    .i2c_data_r         (),   
    .i2c_done           (i2c_done  ),   
    .scl                (cam_scl   ),   
    .sda                (cam_sda   ),   

    .dri_clk            (i2c_dri_clk)               //I2C操作时钟
);
RGBtoYCrCb(
	.Rst(rst_n),
	.clk(cam_pclk),
	.data(wr_data),
	.face_data(face_data1)
	);    

endmodule 