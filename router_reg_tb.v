//Author: Jason Phillips
//The testbench for the reg module. Tests logic for data transfer to the synch and fifo buffer.
`include "router_reg_new.v"
module router_reg_tb;

reg clk1, reset, packet_valid_i;
reg[7:0] packet_in;
reg get_source, get_dest, store_header, get_size, load_data, get_crc, fifo_full, full_state;

wire[2:0] dsize;
wire[7:0] data_out, destination;
wire crc_checked, trusted_source, err;

router_reg_new r1(clk1, reset, packet_valid_i, packet_in, get_source, get_dest, store_header,
				  get_size, load_data, get_crc, fifo_full, full_state,
				  dsize, data_out, destination, crc_checked, trusted_source, err);
				  
initial begin
clk1 = 1'b0; reset = 1'b1; 

@(posedge clk1)
	begin
		packet_in = 8'b10000001; packet_valid_i = 1'b1; fifo_full = 1'b0; get_source = 1'b1;  	
	end
	
@(posedge clk1)	//testing the get destination logic.
	begin
		packet_in = 8'b00001111; get_dest = 1'b1; get_source = 1'b0;
	end
	
@(posedge clk1) //store header state
	begin
		store_header = 1'b1; get_dest = 1'b0;
	end
		
@(posedge clk1) //store the number of data bytes present in the upcoming packets.
	begin
		packet_in = 8'b00000010; get_size = 1'b1; store_header =1'b0;
	end
	
@(posedge clk1)
	begin
		packet_in = 8'b11110000; load_data = 1'b1; get_size = 1'b0;
	end
	
@(posedge clk1)
	begin
		packet_in = 8'b00001111;
	end
	
@(posedge clk1)
	begin
		packet_in = 8'b11111111; get_crc = 1'b1; load_data = 1'b0;
	end
	
//---second pass---
@(posedge clk1)
	begin
		packet_in = 8'b00011000; packet_valid_i = 1'b1; fifo_full = 1'b0; get_source = 1'b1;  get_crc = 1'b0; 	
	end
	
@(posedge clk1)	//testing the get destination logic.
	begin
		packet_in = 8'b00001010; get_dest = 1'b1; get_source = 1'b0;
	end
	
@(posedge clk1) //store header state
	begin
		store_header = 1'b1; get_dest = 1'b0;
	end
		
@(posedge clk1) //store the number of data bytes present in the upcoming packets. 3 bytes of data.
	begin
		packet_in = 8'b00000011; get_size = 1'b1; store_header =1'b0;
	end
	
@(posedge clk1) //data byte 1
	begin
		packet_in = 8'b11110000; load_data = 1'b1; get_size = 1'b0;
	end
	
@(posedge clk1) //databyte 2
	begin
		packet_in = 8'b00001111;
	end

@(posedge clk1) //databyte 3
	begin
		packet_in = 8'b00111110;
	end
	
@(posedge clk1)
	begin
		packet_in = 8'b11111111; get_crc = 1'b1; load_data = 1'b0;
	end
#10 $finish;
end

always #5 clk1 = ~clk1;

initial $monitor("Time:%d, clk:%d, rst:%b, dsize:%d,pktin:%b, dout:%b, dest:%b, crc_check:%b, trust:%b, err:%b, gs:%b, gd:%b, sh:%b, gsz:%b, ld:%b, crc:%b",
				  $time, clk1, reset, dsize, packet_in, data_out, destination, crc_checked, trusted_source, err, get_source, get_dest, store_header, get_size,
						  load_data, get_crc);
						  
initial $vcdpluson;

endmodule