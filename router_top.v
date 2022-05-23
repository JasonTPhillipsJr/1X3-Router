`include "router_fsm_new.v"
`include "router_reg_new.v"
`include "router_sync.v"
`include "asy_fifo.v"
`timescale 100ns/1ns
//Router module. Instantiates all other modules and connects their input/outs to each other and the testbench.
module router_top(input clk1, clk2, reset, packet_valid_i, read_enable_0, read_enable_1, read_enable_2, 
					input [7:0] packet_in, 
					output packet_valid_o1, packet_valid_o2, packet_valid_o3, 
					output [7:0] packet_out0, packet_out1, packet_out2, 
					output stop_packet_send, err);	

wire [2:0] wr_en;
wire [2:0] rd_en;
wire [2:0] empty;					//Comes from fifo, goes to selector.
wire [7:0] data_out;
wire [7:0] destination;
wire [2:0] dsize;
wire [7:0] packet_out_temp[2:0];	//Will store the output of each fifo in a unique index.
wire [2:0] fifo_full;				//The full bit for each unique fifo. Comes from fifo, goes to selector.
wire full;							//This is true if any bit from full_fifo is set to 1.	Comes from selector, goes to reg and fsm.	
wire get_source;
wire get_dest;
wire store_header;
wire get_size;
wire load_data;
wire get_crc;
wire full_state;
wire trusted_source;
wire crc_checked;					//Might remove in a bit, just a lingering wire.
wire write_enb_reg;					//A single bit that come from fsm and sent to selector to choose which fifo to write to.



	genvar i;
	
generate
for(i=0; i<3; i=i+1)


begin:fifo
	asy_fifo fifo(.reset(reset), .wr_en(wr_en[i]), .rd_en(rd_en[i]), .rd_clk(clk2), .wr_clk(clk1), .data_in(data_out[7:0]),
	              .data_out(packet_out_temp[i]), .wr_full(fifo_full[i]), .rd_empty(empty[i]));
	
end
endgenerate

//Memory register. Recieves incoming packets and performs logic on them.
router_reg_new r1(.clk1(clk1), .reset(reset), .packet_valid_i(packet_valid_i),
				  .packet_in(packet_in[7:0]),
                  .get_source(get_source), .get_dest(get_dest), .store_header(store_header), .get_size(get_size),
                  .load_data(load_data), .get_crc(get_crc), .fifo_full(full), .full_state(full_state),
				  .dsize(dsize[2:0]),
                  .data_out(data_out[7:0]), .destination(destination[7:0]),
				  .crc_checked(crc_checked), .trusted_source(trusted_source), .err(err));

//Finite State Machine. Handles the flags for the memory register and for full fifo.
router_fsm fsm(.clk1(clk1), .reset(reset), .packet_valid_i(packet_valid_i),
							.dsize(dsize[2:0]),
							.fifo_full(full), .trusted_source(trusted_source), 
                            .write_enb(write_enb_reg), .get_source(get_source), .get_dest(get_dest), .store_header(store_header), .get_size(get_size), 
                            .load_data(load_data), .get_crc(get_crc), .full_state(full_state), .stop_packet_send(stop_packet_send)); 


//Selector Module. Selects the fifo buffer according to the destination byte we receive from the memory register.
//Also handles telling the testbench that a buffer is free to read from if it isn't empty.
router_sync s(.clk1(clk1), .reset(reset), .get_dest(get_dest), .write_enb_reg(write_enb_reg),
			  .empty_0(empty[0]), .empty_1(empty[1]), .empty_2(empty[2]), .full_0(fifo_full[0]), .full_1(fifo_full[1]), .full_2(fifo_full[2]),
			  .destination(destination[7:0]),
			  .vld_out_0(packet_valid_o1), .vld_out_1(packet_valid_o2), .vld_out_2(packet_valid_o3), 
			  .write_enb(wr_en[2:0]), 
			  .fifo_full(full));

//Tells the fifo buffer to start reading the data to the output port of fifo.
assign rd_en[0]=read_enable_0;
assign rd_en[1]=read_enable_1;
assign rd_en[2]=read_enable_2;

//Take the data out of each fifo buffer and assign the output to the outports of router top.
assign packet_out0=packet_out_temp[0];
assign packet_out1=packet_out_temp[1];
assign packet_out2=packet_out_temp[2];


endmodule
