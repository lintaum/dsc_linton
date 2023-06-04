//==================================================================================================
//  Filename      : dual_port_ram.v
//  Created On    : 2018-05-17 08:31:35
//  Last Modified : 2022-08-26 11:06:24
//  Revision      : 
//  Author        : Linton Esteves
//  Company       : SENAI
//  Email         : linton.esteves@fbter.org.br
//
//  Description   : 
//
//
//==================================================================================================
module dual_port_ram_reg 
	#(
		parameter DATA_WIDTH = 32,
		parameter ADDR_WIDTH = 10
	)
	(
	input clk,    // Clock
	input rst_n,  // Asynchronous reset active low
	input [DATA_WIDTH-1:0] data_i,
	output reg [DATA_WIDTH-1:0] data_o,
	input write_en_i,
	input read_en_i,
	input [ADDR_WIDTH-1:0] read_addr_i,
	input [ADDR_WIDTH-1:0] write_addr_i
);

localparam MEM_SIZE = 2**ADDR_WIDTH;

reg [DATA_WIDTH-1:0] mem [0:MEM_SIZE-1];

always @(posedge clk, negedge rst_n) begin : proc_mem
	if(!rst_n) begin
		// for (int i = 0; i < MEM_SIZE; i++) begin
			// mem[i] <= {DATA_WIDTH{1'b0}};
		// end
	end else begin
		if (write_en_i)
			mem[write_addr_i] <= data_i;
	end
end

always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		data_o <= 0;
	end
	else begin
		// if (read_en_i) begin
			data_o <= mem[read_addr_i];		
		// end
	end
end

// assign data_o = mem[read_addr_i];



endmodule

