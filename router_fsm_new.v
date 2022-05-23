//Author: Jason Phillips
//FSM for router implementation.
//NOTE: This fsm operates under the assumption that we are using three FIFO
//buffers, the soft resets are for each idividual buffer (might not need. have to see implementation first).
`timescale 100ns/1ns
module router_fsm(
	input clk1, reset, packet_valid_i, 
	input[2:0] dsize,				//number of data bytes in packet.
	input fifo_full, trusted_source,	//fifo_empty_0, fifo_empty_1, fifo_empty_2, soft_reset_0, soft_reset_1, soft_reset_2,
	output write_enb, get_source, get_dest, store_header, get_size, load_data, get_crc, full_state, stop_packet_send);
	
parameter
	Store_Header_State = 4'b0001,	
	Check_Source_State = 4'b0010,	//The new initial state
	Get_dest_state = 4'b0011,		//Pull destination bits from packet_in.
	Get_Size_State = 4'b0100,
	Load_Data_State = 4'b0101,
	Check_CRC_State = 4'b0110,
	Wait_Till_Empty_State = 4'b0111, //Might not need, depends on the implementation.
	FIFO_Full_State = 4'b1000;
	
reg[3:0] state, next_state, state_after_wait;
reg[1:0] temp;
reg stored_dest;					//A count variable for storing 2 bytes of data to buffer.

initial begin
	next_state <= Check_Source_State;
end


always@(posedge clk1 or negedge reset)
	begin
		if(!reset)
			state <= Check_Source_State;
		else 
			state <= next_state;
	end

always@(*)
	begin
	
		//next_state = 4'bx;
		
		case(state)
		
			Check_Source_State:		//This is the initial state so we don't miss any packages over a clock cycle.
				begin
					if(packet_valid_i && !fifo_full)
						
						next_state = Get_dest_state;
						
					else if(packet_valid_i && fifo_full)
						begin
						
							next_state = FIFO_Full_State;
							state_after_wait = Check_Source_State;		//After we wait for an available spot, go to the next state.
						
						end
						
					else
					
						next_state = Check_Source_State;
							
				end
				
			Get_dest_state:			//Get the destination byte from the packet. We store source in this state.
				begin
					stored_dest = 0;
					if(packet_valid_i && !fifo_full)
						
						next_state = Store_Header_State;
					
					else if(packet_valid_i && fifo_full)
						begin
						
							next_state = FIFO_Full_State;
							state_after_wait = Get_dest_state;
				
						end
				end
				
			Store_Header_State:		//Stall the testbench and store dest to buffer.
				begin
				
					if((packet_valid_i) && (!fifo_full) && (stored_dest == 0))
						begin
							
							stored_dest = 1;		//We stored dest byte to buffer.
							next_state = Get_Size_State;	//come back to store dest.
							
						end
						
						
					else if((packet_valid_i) && (fifo_full) && (stored_dest == 0))	//If fifo full.
						begin
				
							next_state = FIFO_Full_State;
							state_after_wait = Store_Header_State;
						
						end
				
				end
				
			Get_Size_State:			//Get the data size value from the packet.
				begin
				
					if(packet_valid_i && !fifo_full)
						
						next_state =  Load_Data_State;
					
					else if( packet_valid_i && fifo_full)
					
						begin
						
							next_state = FIFO_Full_State;
							state_after_wait = Get_Size_State;
						
						end
				
				end
				
			Load_Data_State:		//Get every data value from the packet using the dsize variable.
				begin
				
					if(packet_valid_i && (dsize > 0) && !fifo_full)
						
						next_state = Load_Data_State;						
						
					else if(packet_valid_i && (dsize > 0) && fifo_full)
						begin
						
							next_state = FIFO_Full_State;
							state_after_wait = Load_Data_State;			//We come back to this state because there is still more data.
						
						end
						
					else if(packet_valid_i && (dsize == 0) && !fifo_full)
					
						next_state = Check_CRC_State;						//Move to CRC after no more data in packet.
						
					else if(packet_valid_i && (dsize == 0) && fifo_full)
						begin
						
							next_state = FIFO_Full_State;					//Go to full state before attemptint to read any more data.
							state_after_wait = Load_Data_State;			//Go to CRC State after buffer space is made. No more data packets to read.
						
						end
				
				end
				
			Check_CRC_State:
				begin
				
					if(!fifo_full)
						next_state = Check_Source_State;
					else
						begin
						
							next_state = FIFO_Full_State;
							state_after_wait = Check_CRC_State;
						
						end
				end
			//Wait_Till_Empty_State: Not sure if we really need this one yet. router should write to buffer when there is at lease one spot.
			FIFO_Full_State:
				begin
				
					if(fifo_full)
						next_state = FIFO_Full_State;
						
					else
						next_state = state_after_wait; 	//This is saved before a state changes to FIFO_Full_State.
				
				end
			
			default:
			    begin
				next_state= Check_Source_State;
			    end

		    endcase
	end
	
assign stop_packet_send = ((state == Store_Header_State) || (state == FIFO_Full_State) || (fifo_full))?1:0;
assign get_source = ((state == Check_Source_State))?1:0;
assign get_dest = ((state == Get_dest_state))?1:0;
assign get_size = ((state == Get_Size_State))?1:0;
assign load_data = ((state == Load_Data_State))?1:0;
assign get_crc = ((state ==  Check_CRC_State))?1:0;
assign store_header = ((state == Store_Header_State))?1:0;
assign full_state = ((state == FIFO_Full_State))?1:0;

//Enable write to fifo if fsm is in any of these state AND from trusted source, valid packet, and non full fifo.
assign write_enb = (((state == Get_dest_state) || (state == Store_Header_State) || (state == Get_Size_State)
					|| (state == Load_Data_State) || (state == Check_CRC_State)) 
					&& ( trusted_source) && (packet_valid_i) && (!fifo_full))?1:0;
			
endmodule
