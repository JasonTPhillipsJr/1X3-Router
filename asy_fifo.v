
//*********************************************************
//Module: Asynchronous 32 byte FIFO memory with dual clocks
//Description: This moduele has a single 32 byte memory which
//					is controlled by two different clocks. One clock
//					is used to read and other is used to write onto 
//					FIFO.
//Author: Adeel Ghumman
//*********************************************************
`timescale 100ns/1ns
module asy_fifo (reset,wr_en,rd_en, rd_clk, wr_clk, data_in,
					 data_out, wr_full, rd_empty);

input 	  reset;//Single reset
input 	  rd_en, wr_en, rd_clk, wr_clk;//read/write enable and clock signals
output 	  wr_full, rd_empty;//Two flags to show if FIFO is empty or full
input 	  [7:0] data_in;//Since its 32 byte FIFO, FIFO data input is required to be 1 byte = 8 bits
output reg [7:0] data_out;//FIFO Data output is also 1 byte = 8 bits 




//Internal register and wires
reg  [4:0]  rd_sync_1, rd_sync_2;//Used for synching purpose of read pointers, 0 to 4 is 5, 2^5=32
reg  [4:0]  wr_sync_1, wr_sync_2;//Used for synching purpose of write pointers
wire [4:0]  rd_pointer_g,wr_pointer_g;//These hold the gray_code output of binary read/write pointers

//These are 6 bit because we need an extra bit to determine the FIFO's full/empty flags
//Check at the end how this one extra bit is used
reg  [5:0]	  wr_pointer,rd_pointer;// read/write pointers which are incremented to perform read/write operations
wire [5:0]	  wr_pointer_sync,rd_pointer_sync;//They hold the Synched output of read/write pointers





//*********************************************************
//STEP-1: Create memory
//*********************************************************
//creating 32 byte memory (32 registers of 8 bit each)
reg [7:0] mem [31:0];  



initial begin
wr_pointer <= 0;
rd_pointer <= 0;
end
//*********************************************************
//STEP-2: Create Write pointer 
//*********************************************************
//--write logic--//
// write only happens if FIFO is not full and read_enable is high
// If FIFO is not full, increment the write pointer and put data in FIFO
always @(posedge wr_clk or negedge reset) 
	begin
		if (!reset) // reset
			begin 
				wr_pointer <= 0;
			end
		
		else if (wr_en && (wr_full == 1'b0)) 
			begin
				mem[wr_pointer[4:0]] <= data_in; // store data in FIFO at new pointer value
				wr_pointer <= wr_pointer + 1; // increment write pointer
				//here we're only using wr_pointer[4:0] i.e 5 bits. the 6th bit is not needed because memory has depth of 32.
				// only 5 bit addresses are enough to get to any of 32 registers. The same explanation will follow wherever you 
				// see this [4:0].
			end
	end




//*********************************************************
//STEP-3: Create Read pointer 
//*********************************************************
//--read logic--//
// read only happens if FIFO is not empty and write_enable is high
// If FIFO is not empty, increment the read pointer and take data out of FIFO
always @(posedge rd_clk or negedge reset) 
	begin
		if (!reset) 
			begin
				rd_pointer <= 0;
			end
	
		else if (rd_en && (rd_empty == 1'b0)) 
			begin
				data_out <= mem[rd_pointer[4:0]];// Take data out of FIFO at new pointer value
				rd_pointer <= rd_pointer + 1;// increment read pointer
				
			end	
	end




//*********************************************************
//STEP-4: Convert Read/Write binary pointers to Gray code 
//*********************************************************
//--binary code to gray code--//
assign wr_pointer_g = wr_pointer ^ (wr_pointer >> 1);
assign rd_pointer_g = rd_pointer ^ (rd_pointer >> 1);





//*********************************************************
//STEP-5: Synchronize Read/Write pointers
//*********************************************************
//--read pointer synchronizer controled by write clock
//We need two flip flops in synchronizers
always @(posedge wr_clk) begin
	rd_sync_1 <= rd_pointer_g;//First synchronizer flip flip
	rd_sync_2 <= rd_sync_1;//second synchronizer flip flip
end
//--write pointer synchronizer controled by read clock
always @(posedge rd_clk) begin
	wr_sync_1 <= wr_pointer_g;//First synchronizer flip flip
	wr_sync_2 <= wr_sync_1;//second synchronizer flip flip
end






//************************************************************************
//STEP-6: Convert Read/Write Gray pointers back to synched binary pointers 
//************************************************************************
//--gray code to binary code--//
assign wr_pointer_sync = wr_sync_2 ^ (wr_sync_2 >> 1) ^ (wr_sync_2 >> 2) ^ (wr_sync_2 >> 3);
assign rd_pointer_sync = rd_sync_2 ^ (rd_sync_2 >> 1) ^ (rd_sync_2 >> 2) ^ (rd_sync_2 >> 3);





//************************************************************************
//STEP-7: logic for Full and empty signals
//************************************************************************
//When only MSB of read pointer and write pointer do not match, FIFO is full
assign wr_full = ((wr_pointer[4:0] == rd_pointer_sync[4:0]) && (wr_pointer[5] != rd_pointer_sync[5] ));

//When read pointer's bits are equal to write pointer's bits, FIFO is Empty
assign rd_empty = (wr_pointer_sync == rd_pointer)?1'b1:1'b0;

endmodule

