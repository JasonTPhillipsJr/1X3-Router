`include "asy_fifo.v"
`timescale 100ns/100ns
module asy_fifo_tb ();
//Inputs are declared as REG and outputs are declared as WIRE in testbench
reg  reset,wr_en,rd_en, rd_clk, wr_clk;
wire wr_full, rd_empty;
reg  [7:0] data_in;
wire [7:0] data_out;


//Instantiating FIFO module
asy_fifo UUT (reset,wr_en,rd_en, rd_clk, wr_clk, data_in,
				 data_out, wr_full, rd_empty);


//Read clock f=100Khz (T=10us)
initial begin
 rd_clk = 0;
 forever #50 rd_clk = !rd_clk;
end

//Write clock f=250Khz (T=4us)
initial begin
 wr_clk = 0;
 forever #20 wr_clk = !wr_clk;
end

integer i;

initial begin
//At start system is in reset state
//wr_en and rd_en are also disabled
//data_in is set to zero 
 reset = 0; 
 wr_en = 0;
 rd_en = 0;
 data_in = 8'd0;
 
//After 4us reset is disabled
@(posedge wr_clk)
begin
	reset = 1;
	wr_en = 1;
end

@(posedge rd_clk)
	 rd_en=1;

//Writing is done first
 //wr_en=1;
  //changed
// #140 wr_en=0;

//reading the FIFO
 //#100 rd_en=1;
 #800 rd_en=0; 
 wr_en=0; //chNGED
 
//Stopping simulation
 #100 $finish;
end

//Reading data from memory file
reg [7:0] mem_read [31:0]; 
always @(posedge wr_clk) begin
 if(!reset && wr_en && !wr_full) begin //writes only if FIFO isn't full
	$display("Writing data to FIFO Memory");
	$readmemb("FIFO_mem.txt", mem_read);//txt file data is given as input
	for(i=0; i<32; i=i+1) begin
	data_in = mem_read[i]; // use this or below
	$display("reset:%b wr_en:%b  rd_en:%b  Address:%d data_in:%d data_out:%d  wr_full:%b  wr_empty:%b",
				reset, wr_en, rd_en, i, data_in, data_out, wr_full, rd_empty);	
#4;
	end
 end
end


//Read operation
always @(posedge rd_clk) begin
 if(!reset && rd_en && !rd_empty) begin//Read only if FIFO isn't empty
	$display("\nReading data from FIFO Memory");
	for(i=0; i<32; i=i+1) begin
	$display("reset:%b wr_en:%b  rd_en:%b  Address:%d data_in:%d data_out:%d  wr_full:%b  wr_empty:%b",
				reset, wr_en, rd_en, i, data_in, data_out, wr_full, rd_empty);	
    //	#10; 
    #2;
	end
 end
end

initial $vcdpluson;


endmodule


