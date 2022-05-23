`timescale 100ns/1ns
//Selecting which fifo to send the data to.
module router_sync(input clk1, reset, get_dest, write_enb_reg,
				   input empty_0, empty_1, empty_2, full_0, full_1, full_2,
				   input[7:0]destination,	//Destination byte.
				   output wire vld_out_0, vld_out_1, vld_out_2,
				   output reg [2:0] write_enb,	//fifo 0 = 001, fifo 1 = 010, fifo 2 = 100, otherwise don't write to any = 000.
				   output reg fifo_full);

reg [7:0]temp;

always@(posedge clk1 or negedge reset)
	begin
	
		if(!reset)
			temp <= 8'b00000000;
		else if(get_dest)		//If the router is pulling the destination byte, store the destination byte in temp.
			temp <= destination;
	end
	
//This will always check to see if any of the fifo buffers are full	
//If the buffer that the destination is trying to go to is full then the fifo as a whole will just be flagged as full.
//Then we will need to wait until space is available before writting values to that buffer.
//These outputs should be connected to the fsm, disabling the write feature.
always@(*)
	begin
	
		if((destination <= 8'd127) && (destination > 8'd0))
			fifo_full = full_0;
		else if((destination <= 8'd195) && (destination > 8'd128))
			fifo_full = full_1;
		else if((destination <= 8'd255) && (destination > 8'd196))
			fifo_full = full_2;
		else
			fifo_full = 0;
		
	end

//The write_enb will be wired to each fifo.
//the first bit will be sent to fifo 0.
//the second bit will be sent to fifo 1.
//the third bit will be sent to fof 2.
//Whichever bit is a 1, that fifo will be enabled to write to.	
always@(*)
	begin
	
		if(write_enb_reg)		//This is different from write_enb. If the write flag is enabled proceed.
			begin
			
				if((destination <= 8'd127) && (destination > 8'd0))
					write_enb = 3'b001;		//write to the first buffer.
				else if((destination <= 8'd195) && (destination > 8'd128))
					write_enb = 3'b010;		//write to the second buffer.
				else if((destination <= 8'd255) && (destination > 8'd196))
					write_enb = 3'b100;		//write to the third buffer.
				else
					write_enb = 3'b000;		//Do not write to any buffer.
			
			end
		
		else
			write_enb = 3'b000;				//sets all fifo buffers write_enab to 0;
	
	end

//a valid output is marked true if a buffer is not empty.
//If a buffer is empty, then vld output should be flagged as 0 (false) and reading from fifo should be disabled.
//If a buffer is not empty, this gets outputted to the testbench and the testbench then asserts read_enabled 0,1, or 2.
assign vld_out_0 = !empty_0;
assign vld_out_1 = !empty_1;
assign vld_out_2 = !empty_2;



endmodule