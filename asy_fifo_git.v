`timescale 100ns/1ns
module asy_fifo (reset,wr_en,rd_en, rd_clk, wr_clk, data_in,
					 data_out, wr_full, rd_empty);

input 	  reset;
input 	  rd_en, wr_en, rd_clk, wr_clk;
output 	  wr_full, rd_empty;
input 	  [7:0] data_in;
output reg [7:0] data_out;




reg  [4:0]  rd_sync_1, rd_sync_2;
reg  [4:0]  wr_sync_1, wr_sync_2;
wire [4:0]  rd_pointer_g,wr_pointer_g;



reg  [5:0]	  wr_pointer,rd_pointer;
wire [5:0]	  wr_pointer_sync,rd_pointer_sync;




reg [7:0] mem [31:0];  




always @(posedge wr_clk or posedge reset) begin
	if (reset) begin
		wr_pointer <= 0;
	end
	else if (wr_en && wr_full == 1'b0) begin
		mem[wr_pointer[4:0]] <= data_in;
		wr_pointer <= wr_pointer + 1;
	end
end




always @(posedge rd_clk or posedge reset) begin
	if (reset) begin
		rd_pointer <= 0;
	end
	else if (rd_en && rd_empty == 1'b0) begin
		data_out <= mem[rd_pointer[4:0]];
		rd_pointer <= rd_pointer + 1;
		
	end
end




assign wr_pointer_g = wr_pointer ^ (wr_pointer >> 1);
assign rd_pointer_g = rd_pointer ^ (rd_pointer >> 1);





always @(posedge wr_clk) begin
	rd_sync_1 <= rd_pointer_g;
	rd_sync_2 <= rd_sync_1;
end

always @(posedge rd_clk) begin
	wr_sync_1 <= wr_pointer_g;
	wr_sync_2 <= wr_sync_1;
end



assign wr_pointer_sync = wr_sync_2 ^ (wr_sync_2 >> 1) ^ (wr_sync_2 >> 2) ^ (wr_sync_2 >> 3);
assign rd_pointer_sync = rd_sync_2 ^ (rd_sync_2 >> 1) ^ (rd_sync_2 >> 2) ^ (rd_sync_2 >> 3);


assign wr_full = ((wr_pointer[4:0] == rd_pointer_sync[4:0]) && (wr_pointer[5] != rd_pointer_sync[5] ));

assign rd_empty = (wr_pointer_sync == rd_pointer)?1'b1:1'b0;

endmodule

