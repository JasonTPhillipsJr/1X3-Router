//The testbench for the router sync module, or the module that selects the fifo buffer to store output.
`include "router_sync.v"
module router_synce_tb;

reg clk1, reset, get_dest, write_enb_reg, empty_0, empty_1, empty_2, full_0, full_1, full_2;
reg[7:0] destination;

wire vld_out_0, vld_out_1, vld_out_2;
wire [2:0] write_enb;
wire fifo_full;

router_sync s1(clk1, reset, get_dest, write_enb_reg, empty_0, empty_1, empty_2, full_0, full_1, full_2,
			   destination, vld_out_0, vld_out_1, vld_out_2, write_enb, fifo_full);
			   
initial begin
clk1 = 1'b0; reset = 1'b1;

@(posedge clk1)
	begin
		destination = 8'b10001111; get_dest = 1'b0; write_enb_reg = 1'b1; 
		empty_0 = 1'b0; empty_1 = 1'b1; empty_2 = 1'b1;
	end

@(posedge clk1)
	begin
		get_dest = 1'b1;
	end
	
@(posedge clk1)
	begin
		write_enb_reg = 1'b0;
	end
	
#10 $finish;

end

always #5 clk1 = ~clk1;

initial $monitor("Time:%d, clk:%d, rst:%d, Dest:%b, WriteTo:%b, out0:%b, out1:%b, out2:%b, full:%b, gd:%b",
				  $time, clk1, reset, destination, write_enb, vld_out_0, vld_out_1, vld_out_2, fifo_full, get_dest);


initial $vcdpluson;
endmodule

