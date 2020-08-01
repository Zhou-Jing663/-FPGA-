module ov7725_rgb565_640x480_vga(    
    input                 sys_clk     ,  //ϵͳʱ��
    input                 sys_rst_n   ,  //ϵͳ��λ���͵�ƽ��Ч
    //����ͷ�ӿ�
    input                 cam_pclk    ,  //cmos ��������ʱ��
    input                 cam_vsync   ,  //cmos ��ͬ���ź�
    input                 cam_href    ,  //cmos ��ͬ���ź�
    input        [7:0]    cam_data    ,  //cmos ����
    output                cam_rst_n   ,  //cmos ��λ�źţ��͵�ƽ��Ч
    output                cam_sgm_ctrl,  //cmos ʱ��ѡ���ź�, 1:ʹ������ͷ�Դ��ľ���
    output                cam_scl     ,  //cmos SCCB_SCL��
    inout                 cam_sda     ,  //cmos SCCB_SDA��   
    //VGA�ӿ�                          
    output                vga_hs      ,  //��ͬ���ź�
    output                vga_vs      ,  //��ͬ���ź�
    output        [11:0]  vga_rgb     ,   //��������ԭɫ��� 
    
    output led0,
    output led1,
    output led2,
    output led3
    );

//parameter define
parameter  SLAVE_ADDR =  7'h21        ;  //OV7725��������ַ7'h21
parameter  BIT_CTRL   =  1'b0         ;  //OV7725���ֽڵ�ַΪ8λ  0:8λ 1:16λ
parameter  CLK_FREQ   = 26'd25_000_000;  //i2c_driģ�������ʱ��Ƶ�� 25MHz
parameter  I2C_FREQ   = 18'd250_000   ;  //I2C��SCLʱ��Ƶ��,������400KHz
parameter  CMOS_H_PIXEL = 24'd640     ;  //CMOSˮƽ�������ظ���,��������SDRAM�����С
parameter  CMOS_V_PIXEL = 24'd480     ;  //CMOS��ֱ�������ظ���,��������SDRAM�����С

//wire define
reg                  clk_25m         ;  //25mhzʱ��,�ṩ��vga����ʱ��
reg                   count ;           //���ڲ���25MHzʱ��
wire                  rst_n           ;
                                      
wire                  i2c_exec        ;  //I2C����ִ���ź�
wire   [15:0]         i2c_data        ;  //I2CҪ���õĵ�ַ������(��8λ��ַ,��8λ����)          
wire                  cam_init_done   ;  //����ͷ��ʼ�����
wire                  i2c_done        ;  //I2C�Ĵ�����������ź�
wire                  i2c_dri_clk     ;  //I2C����ʱ��
                                      
wire                  wr_en           ;  //FIFOģ��дʹ��
wire   [15:0]         wr_data         ;  //����ͷ����
wire                  rd_en           ;  //FIFO��ʹ��
reg   [11:0]         rd_data         ;  //VGA������
wire                  sys_init_done   ;  //ϵͳ��ʼ�����(sdram��ʼ��+����ͷ��ʼ��)
wire                  dout           ;  //FIFO���
wire face_data1;
wire face_data2;
wire face_data3;
reg [18:0] addra;
reg [18:0] addrb;
reg wea1;
reg wea2;
reg wr_clk;
wire           cmos_frame_href; //����ͷhang��Ч�ı�־
wire cmos_frame_vsync;//zhen��Ч��־
reg cam_vsync_wire;
assign led0 = face_data1 ? 1'b1 : 1'b0;
assign  rst_n = sys_rst_n ;
//ϵͳ��ʼ����ɣ�RAM������ͷ����ʼ�����
assign  sys_init_done =   cam_init_done;
//��������ͷӲ����λ,�̶��ߵ�ƽ
assign  cam_rst_n = 1'b1;
//cmos ʱ��ѡ���ź�,0:ʹ������XCLK�ṩ��ʱ�� 1:ʹ������ͷ�Դ��ľ���
assign  cam_sgm_ctrl = 1'b1;
//FIFOдʱ��
always @ (posedge cam_pclk) begin
    if(!sys_rst_n)
        wr_clk <= 0 ;
    else
        wr_clk = ~wr_clk;
    end
//25MHzʱ��
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
//CMOSͼ�����ݲɼ�ģ��
cmos_capture_data u_cmos_capture_data(
    .rst_n              (rst_n & sys_init_done),    //ϵͳ��ʼ�����֮���ٿ�ʼ�ɼ�����
   
    .cam_pclk           (cam_pclk),
    .cam_vsync          (cam_vsync),
    .cam_href           (cam_href),
    .cam_data           (cam_data),   
   
    .cmos_frame_vsync   (cmos_frame_vsync),
    .cmos_frame_href    (cmos_frame_href),       //����Ч��Ϣ
    .cmos_frame_valid   (wr_en),                    //������Чʹ���ź�
    .cmos_frame_data    (wr_data)                  //��Ч���� 
    );	
//VGA����ģ��
vga_driver u_vga_driver(
    .vga_clk            (clk_25m),    
    .sys_rst_n          (rst_n),  
    .vga_hs             (vga_hs),       
    .vga_vs             (vga_vs),       
    .vga_rgb            (vga_rgb),      
        
    .pixel_data         (rd_data), 
    .data_req           (rd_en),                    //�������ص���ɫ��������
    .pixel_xpos         (), 
    .pixel_ypos         ()
    ); 
//I2C����ģ��    
i2c_ov7725_rgb565_cfg u_i2c_cfg(
    .clk                (i2c_dri_clk),
    .rst_n              (rst_n),
            
    .i2c_done           (i2c_done),
    .i2c_exec           (i2c_exec),
    .i2c_data           (i2c_data),
    .init_done          (cam_init_done)
    );    

//I2C����ģ��
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
    .i2c_rh_wl          (1'b0),                     //�̶�Ϊ0��ֻ�õ���IIC������д����   
    .i2c_addr           (i2c_data[15:8]),   
    .i2c_data_w         (i2c_data[7:0]),   
    .i2c_data_r         (),   
    .i2c_done           (i2c_done  ),   
    .scl                (cam_scl   ),   
    .sda                (cam_sda   ),   

    .dri_clk            (i2c_dri_clk)               //I2C����ʱ��
);
RGBtoYCrCb(
	.Rst(rst_n),
	.clk(cam_pclk),
	.data(wr_data),
	.face_data(face_data1)
	);    

endmodule 