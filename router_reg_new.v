//Author: Jason Phillips
`timescale 100ns/1ns
//Router Register Module. Stores the packets as they come in and identifies source, dest, size, data, and crc bits.
module router_reg_new(input clk1, reset, packet_valid_i,
					  input[7:0] packet_in,
					  input get_source, get_dest, store_header, get_size, load_data, get_crc, fifo_full, full_state, 
					  output reg[2:0] dsize,
					  output reg[7:0] data_out, destination,
					  output reg crc_checked, trusted_source, err);

parameter					//only routes packages if source byte matches either of these.
		TS1 = 8'b10000001,
		TS2 = 8'b10000011,
		TS3 = 8'b10000111;
reg[7:0] source_byte, dest_byte, size_byte, data_byte, crc_byte;
reg[7:0] internal_crc; 		//The byte that will be holding all the xor values.


//initial begin	
//internal_crc <= 8'b0;
//end

//Indentify source_byte
always@(get_source or get_dest or store_header or get_size or load_data or get_crc or fifo_full or full_state)
	begin
		if(!reset)
			begin
				source_byte = 8'b0;
				trusted_source = 1'b0;
				dest_byte = 8'b0;
				destination = 8'b0;
				size_byte = 8'b0;
				dsize = 3'b0;
				data_byte = 8'b0;
				internal_crc = 8'b0;
				crc_byte = 8'b0;
				err = 1'b0;
			end
		
		else
			begin
			
				if(get_source)
					begin
						//at the start of the initial state, reset all the registers 
						internal_crc = 8'b0;
						source_byte = 8'bx;
						dest_byte =  8'bx;
						size_byte = 8'bx;
						data_byte = 8'bx;
						crc_byte = 8'bx;
						trusted_source = 1'bx;
						crc_checked = 1'bx;
						data_out = 8'bx;
						destination = 8'bx;
						err = 1'bx;
						
						if(packet_valid_i && !fifo_full)
							begin
								
								source_byte = packet_in;
								
								if((source_byte == TS1) || (source_byte == TS2) || (source_byte ==TS3))
									begin
						
										trusted_source = 1'b1;		//Once this switches to on, the write_enb get turned on in the fsm, allowing for writes in fifo.
								
									end
								else
									trusted_source = 1'b0;		//disables write function until a valid packet comes or fifo is free.
							
							end
					
					end
				
				else if(get_dest)
					begin
					
						if(packet_valid_i && !fifo_full)
							begin
							
								dest_byte = packet_in;
								destination = packet_in;		//Send destination byte to sync module.
								data_out = source_byte;		//store previous byte on the buffer. We will stall the tb from recieveing anymore in this state as well.
							
							end
					
					end
		
				
				else if(store_header)		//When in this state, fsm disables packet_send.
					begin
					
						if(packet_valid_i && !fifo_full)
							begin
							
								data_out = dest_byte; 	//stores  onto the buffer now.
																		
							end
					
					end
			
				else if(get_size)		//When we get to this state, the fsm re-enables packet_send because we caught up now.
					begin
					
						if(packet_valid_i && !fifo_full)
							begin
							
								size_byte = packet_in;
								dsize = packet_in[2:0];	//sends the number of data bytes to fsm. Will use to count how many bytes we need to read before end of packet.
								data_out = packet_in;		//store this on the buffer.
							
							end
					
					end
	
			
				else if(load_data)
				    begin
					
						if(packet_valid_i && !fifo_full && (dsize != 0))
						    begin
								data_byte = packet_in;
								internal_crc = internal_crc ^ packet_in;
								dsize = dsize - 1;
								data_out = packet_in;
							
							end
					
					end
	

				else if(get_crc)
					begin
					
						if(packet_valid_i && !fifo_full)
							begin
							
								crc_byte = packet_in;
								data_out = packet_in;
								
								if(packet_in == internal_crc)
									begin
										crc_checked = 1'b1; 
										err = 1'b0;		//no error.
									end
								else
									begin
										crc_checked = 1'b1; 
										err = 1'b1;		//error.
									end
							end
					
					end
			
			end
	
	end
	


endmodule