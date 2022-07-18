//Authors: Jason Phillips, Harjot Sidhu
`include "router_top.v"
//100KHz = 10000ns(p) & 250KHz = 4000 ns(p)
//2000ns = half cycle for clk1		#20 for half period, #40 for full period.
//5000ns = half cycle for clk2		#50 for half period, #100 for full period.
`timescale 100ns/1ns

module router_top_tb;

reg clk1, clk2, reset, packet_valid_i, read_enable_0, read_enable_1, read_enable_2;	//inputs to the router.
reg[7:0] packet_in;
wire packet_valid_o1, packet_valid_o2, packet_valid_o3;	//outputs from router.
wire[7:0] packet_out0, packet_out1, packet_out2;
wire stop_packet_send, err;
		
router_top UUT(.clk1(clk1), .clk2(clk2), .reset(reset), .packet_valid_i(packet_valid_i),
			   .read_enable_0(read_enable_0), .read_enable_1(read_enable_1), .read_enable_2(read_enable_2),
			   .packet_in(packet_in[7:0]), 
			   .packet_valid_o1(packet_valid_o1), .packet_valid_o2(packet_valid_o2), .packet_valid_o3(packet_valid_o3),
			   .packet_out0(packet_out0[7:0]), .packet_out1(packet_out1[7:0]), .packet_out2(packet_out2[7:0]),
			   .stop_packet_send(stop_packet_send), .err(err));
	
	
//reg[7:0] temp;
reg [7:0] mem_read [32:0]; 
integer i;

initial begin
clk1 = 1'b0; clk2 = 1'b0; reset = 1'b1; packet_valid_i = 1'b0; read_enable_0 = 1'b0; read_enable_1 = 1'b0; read_enable_2 = 1'b0;
i = 0;

//--Scenario 1-- Untrusted source
@(posedge clk1)
	packet_in = 8'b10000001; packet_valid_i = 1'b1;
@(posedge clk1)
	packet_in = 8'b00001111;
@(posedge clk1)
	packet_in = 8'b00000010;
@(posedge clk1)
	packet_in = 8'b11110000;
@(posedge clk1)
	packet_in = 8'b00001111;
@(posedge clk1)
	packet_in = 8'b11111111;
	
//--Scenario 2 -- Trusted source and a different destination
@(posedge clk1)
	packet_in = 8'b10000001; packet_valid_i = 1'b1;
@(posedge clk1)
	packet_in = 8'b10011111;	
@(posedge clk1)
	packet_in = 8'b00000010;
@(posedge clk1)
	packet_in = 8'b11110000;
@(posedge clk1)
	packet_in = 8'b00001111;
@(posedge clk1)
	packet_in = 8'b11111111;
	
//--Scenario 3 -- Untrusted source and a different destination
@(posedge clk1)
	packet_in = 8'b00000001; packet_valid_i = 1'b1;
@(posedge clk1)
	packet_in = 8'b10001111;	
@(posedge clk1)
	packet_in = 8'b00000010;
@(posedge clk1)
	packet_in = 8'b11110000;
@(posedge clk1)
	packet_in = 8'b00001111;
@(posedge clk1)
	packet_in = 8'b11111111;
	


#500 $finish;	
end	

//always@(posedge clk1)
	//begin
		//packet_valid_i = 1'b1;
		//if((!stop_packet_send) && (i < 33))
			//begin
				//$readmemb("FIFO_mem.txt", mem_read);
				//packet_in = mem_read[i]; 
				//i = i+1;
			//end
		
		
	//end
	
	
always@(posedge clk2)
	begin
		if(packet_valid_o1)
			read_enable_0 = 1'b1;
		
		else if(packet_valid_o2)
			read_enable_1 = 1'b1;
		
		else if(packet_valid_o3)
			read_enable_2 = 1'b1;	
			
		else
			begin
			
				read_enable_0 = 1'b0;
				read_enable_1 = 1'b0;
				read_enable_2 = 1'b0;
			
			end
	end
		
always begin
	#20 clk1 = ~clk1;	//every 2000ns switch.
	#50 clk2 = ~clk2;	//every 5000ns swtich.
end

initial $monitor("Time:%0d, clk1:%b, clk2:%b, rst:%b, packet_valid:%b, r_en0:%b, r_en1:%b, r_en2:%b, pktIn:%b, out0:%b, out1:%b, out2:%b, err:%b", 
				  $time, clk1, clk2, reset, packet_valid_i, read_enable_0, read_enable_1, read_enable_2, packet_in,
					packet_out0, packet_out1, packet_out2, err);

initial $vcdpluson;
	
endmodule
	

