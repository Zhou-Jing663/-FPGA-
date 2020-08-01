//本人编写
module RGBtoYCrCb(
	input Rst,
	input clk,
	input [15:0] data,
	output reg face_data
	);
	
	wire [8:0] R0;
	wire [8:0] G0;
	wire [8:0] B0;
	reg [15:0] R1;
	reg [15:0] G1;
	reg [15:0] B1;
	reg [15:0] R2;
	reg [15:0] G2;
	reg [15:0] B2;
	reg [15:0] R3;
	reg [15:0] G3;
	reg [15:0] B3;
	
	reg [15:0] Y1;
	reg [15:0] Cb1;
	reg [15:0] Cr1;
	reg [7:0] Y2;
	reg [7:0] Cb2;
	reg [7:0] Cr2;
	
	assign R0 = { data[15:11] , data[13:11] };
	assign G0 = { data[10:5] , data[6:5] };
	assign B0 = { data[4:0] , data[2:0] };
	
	always @ ( posedge  clk or negedge Rst) begin
		if(!Rst) begin
			{R1,G1,B1} <= { 16'd0 , 16'd0 , 16'd0 } ;
			{R2,G2,B2} <= { 16'd0 , 16'd0 , 16'd0 } ;
			{R3,G3,B3} <= { 16'd0 , 16'd0 , 16'd0 } ;
		end
		else begin
			{R1,G1,B1} <= { {R0 * 16'd77} , {G0 * 16'd150} , {B0 * 16'd29} } ;
			{R2,G2,B2} <= { {R0 * 16'd43} , {G0 * 16'd85} , {B0 * 16'd128} } ;
			{R3,G3,B3} <= { {R0 * 16'd128} , {G0 * 16'd107} , {B0 * 16'd21} } ;
		end
	end
	
	always @ ( posedge clk or negedge Rst) begin
		if(!Rst) begin
			Y1 <= 16'd0 ;
			Cb1 <= 16'd0 ;
			Cr1 <= 16'd0 ;
		end
		else begin
			Y1 <= R1 + G1 + B1;
			Cb1 <= -R2 - G2 + B2 + 16'd32768;
			Cr1 <= R3 - G3 -B3 + 16'd32768;
		end
	end
	
	always @ ( posedge clk or negedge Rst) begin
		if(!Rst) begin
			Y2 <= 8'd0 ;
			Cb2 <= 8'd0 ;
			Cr2 <= 8'd0 ;
		end
		else begin
			Y2 <= Y1[15:8] ;
			Cb2 <= Cb1[15:8] ;
			Cr2 <= Cr1[15:8] ;
		end
	end
	
	always @ ( posedge clk or negedge Rst) begin
		if(!Rst) begin
			face_data <= 1'b0;
		end
		else if( (Cb2 > 77) && (Cb2 < 127) && (Cr2 > 133) && (Cr2 <173) ) begin
			face_data <= 1'b1;
		end
		else begin
			face_data <= 1'b0;
		end
	end
endmodule			