
`timescale 1us/1ps
module asy_fifo_tb ();

reg  reset,wr_en,rd_en, rd_clk, wr_clk;
wire wr_full, rd_empty;
reg  [7:0] data_in;
wire [7:0] data_out;



asy_fifo UUT (reset,wr_en,rd_en, rd_clk, wr_clk, data_in,
				 data_out, wr_full, rd_empty);



initial begin
 rd_clk = 0;
 forever #5 rd_clk = !rd_clk;
end


initial begin
 wr_clk = 0;
 forever #2 wr_clk = !wr_clk;
end

integer i;

initial begin

 reset = 1; 
 wr_en = 0;
 rd_en = 0;
 data_in = 8'd0;
 

 #4;
 reset = 0; 


 wr_en=1;
 rd_en=1;


 #400 rd_en=0; 
 wr_en=0;
 

 #100 $stop;
end


reg [7:0] mem_read [31:0]; 
always @(posedge wr_clk) begin
 if(!reset && wr_en && !wr_full) begin 
	$display("Writing data to FIFO Memory");
	$readmemb("FIFO_mem.txt", mem_read);
	for(i=0; i<32; i=i+1) begin
	data_in = mem_read[i]; 
	$display("reset:%b wr_en:%b  rd_en:%b  Address:%d data_in:%d data_out:%d  wr_full:%b  wr_empty:%b",
				reset, wr_en, rd_en, i, data_in, data_out, wr_full, rd_empty);	
#4;
	end
 end
end



always @(posedge rd_clk) begin
 if(!reset && rd_en && !rd_empty) begin
	$display("\nReading data from FIFO Memory");
	for(i=0; i<32; i=i+1) begin
	$display("reset:%b wr_en:%b  rd_en:%b  Address:%d data_in:%d data_out:%d  wr_full:%b  wr_empty:%b",
				reset, wr_en, rd_en, i, data_in, data_out, wr_full, rd_empty);	
    #2;
	end
 end
end

endmodule


