//Author: Jason Phillips
//The testbench for the fsm. Tests logic and state transitions.
`include "router_fsm_new.v"
module router_fsm_tb;

reg clk1, reset, packet_valid_i;
reg fifo_full, trusted_source;
reg[2:0] dsize;

wire write_enb, get_source, get_dest, store_header, get_size, load_data, get_crc, full_state, stop_packet_send;

router_fsm f1(clk1, reset, packet_valid_i, 
			  dsize, 
			  fifo_full, trusted_source, 
			  write_enb, get_source, get_dest, store_header, get_size, load_data, get_crc, full_state, stop_packet_send);

initial begin
clk1 = 1'b0;  reset = 1'b1;

@(posedge clk1)				//Simulating Get source state.
	begin
		packet_valid_i = 1'b1; 
		fifo_full = 1'b0;
		trusted_source = 1'b1;
	end
	
@(posedge clk1)				//Simulating Get Desti state. send source byte to buffer
	reset = 1'b1;			//Do nothing as long as inputs keep coming and are valid.
	
@(posedge clk1)				//Simulating Load header state. sends dest byte to buffer
	reset = 1'b1;

	
@(posedge clk1)				//Simulating get size state.
	dsize = 3'd2;			//2 bytes of data in packet.
	
@(posedge clk1)				// 1 byte left of data
	dsize = 3'd1;
	
@(posedge clk1)				// We should now be in crc state. Store that in buffer.
	dsize = 3'd0;
	
@(posedge clk1)				//Now we should be back to initial state.
	reset = 1'b1;			
	
//---------------------new scenario (testing full state)---------------

@(posedge clk1)				//advance one state.
	reset = 1'b1;
	
@(posedge clk1)				//simulate full fifo.
	fifo_full = 1'b1;
	
@(posedge clk1)				//simulate a full fifo for two clock cycles.
	fifo_full = 1'b1;
	
@(posedge clk1)
	fifo_full = 1'b0;		//simulate fifo being freed up and ready to go again.


	

	

#100 $finish;
end

always #5 clk1 = ~clk1;

initial $monitor("Time:%d, clk:%d, rst:%b, PV:%b, w_en:%b, g_src:%b, g_dst:%b, st_hdr:%b, g_sz:%b, ld_d:%b, g_crc:%b, full_st:%b, stp_pckt:%b, full:%b, dsize:%d",
				  $time, clk1, reset, packet_valid_i, write_enb,
				  get_source, get_dest,store_header, get_size, load_data,
				  get_crc, full_state, stop_packet_send,fifo_full,dsize);

initial $vcdpluson;
endmodule