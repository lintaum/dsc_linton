//==================================================================================================
//  Filename      : dual_port_ram.v
//  Created On    : 2018-05-17 08:31:35
//  Last Modified : 2022-10-12 09:44:18
//  Revision      : 
//  Author        : Linton Esteves
//  Company       : SENAI
//  Email         : linton.esteves@fbter.org.br
//
//  Description   : 
//
//
//==================================================================================================
module dual_port_ram 
	#(
		parameter DATA_WIDTH = 32,
		parameter ADDR_WIDTH = 10
	)
	(
	input clk,    // Clock
	input rst_n,  // Asynchronous reset active low
	input [DATA_WIDTH-1:0] data_i,
	input write_en_i,
	input read_en_i,
	input [ADDR_WIDTH-1:0] write_addr_i
	input [ADDR_WIDTH-1:0] read_addr0_i,
	input [ADDR_WIDTH-1:0] read_addr1_i,
	input [ADDR_WIDTH-1:0] read_addr2_i,
	input [ADDR_WIDTH-1:0] read_addr3_i,
	input [ADDR_WIDTH-1:0] read_addr4_i,
	input [ADDR_WIDTH-1:0] read_addr5_i,
	input [ADDR_WIDTH-1:0] read_addr6_i,
	input [ADDR_WIDTH-1:0] read_addr7_i,
	output [DATA_WIDTH-1:0] data0_o,
	output [DATA_WIDTH-1:0] data1_o,
	output [DATA_WIDTH-1:0] data2_o,
	output [DATA_WIDTH-1:0] data3_o,
	output [DATA_WIDTH-1:0] data4_o,
	output [DATA_WIDTH-1:0] data5_o,
	output [DATA_WIDTH-1:0] data6_o,
	output [DATA_WIDTH-1:0] data7_o,
);

localparam MEM_SIZE = 2**ADDR_WIDTH;

reg [DATA_WIDTH-1:0] mem [0:MEM_SIZE-1];

always @(posedge clk, negedge rst_n) begin : proc_mem
	if(!rst_n) begin
		// for (int i = 0; i < MEM_SIZE; i++) begin
		// 	mem[i] <= {DATA_WIDTH{1'b0}};
		// end
	end else begin
		if (write_en_i)
			mem[write_addr_i] <= data_i;
	end
end

assign data0_o = mem[read_addr0_i];
assign data1_o = mem[read_addr1_i];
assign data2_o = mem[read_addr2_i];
assign data3_o = mem[read_addr3_i];
assign data4_o = mem[read_addr4_i];
assign data5_o = mem[read_addr5_i];
assign data6_o = mem[read_addr6_i];
assign data7_o = mem[read_addr7_i];

endmodule

