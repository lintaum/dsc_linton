//==================================================================================================
//  Filename      : ram.v
//  Created On    : 2018-05-16 09:59:54
//  Last Modified : 2018-05-19 08:29:00
//  Revision      : 
//  Author        : Linton Esteves
//  Company       : 
//  Email         : linton.esteves@fbter.org.br
//
//  Description   : 
//
//
//==================================================================================================
module ram 
	#(
		parameter DATA_WIDTH = 32,
		parameter ADDRESS_WIDTH = 10
	)
	(
	input clk,    // Clock
	input rst_n,  // Asynchronous reset active low
	input [DATA_WIDTH-1:0] data_i,
	output [DATA_WIDTH-1:0] data_o,
	input write_en_i,
	// input read_en_i,
	input [ADDRESS_WIDTH-1:0] address_i
);

localparam MEM_SIZE = 2**ADDRESS_WIDTH;

reg [DATA_WIDTH-1:0] mem [0:MEM_SIZE-1];

integer i;

always @(posedge clk, negedge rst_n) begin : proc_mem
	if(!rst_n) begin
		for (i = 0; i < MEM_SIZE; i++) begin
			mem[i] <= {DATA_WIDTH{1'b0}};
		end
	end else begin
		if (write_en_i)
		mem[address_i] <= data_i;
	end
end

assign data_o = mem[address_i];

endmodule