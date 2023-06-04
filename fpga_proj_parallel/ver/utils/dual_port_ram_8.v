//==================================================================================================
//  Filename      : dual_port_ram.v
//  Created On    : 2018-05-17 08:31:35
//  Last Modified : 2022-11-29 11:40:57
//  Revision      : 
//  Author        : Linton Esteves
//  Company       : SENAI
//  Email         : linton.esteves@fbter.org.br
//
//  Description   : 
//
//
//==================================================================================================
module dual_port_ram_8 
	#(
		parameter DATA_WIDTH = 32,
		parameter ADDR_WIDTH = 10,
		parameter NUM_PORTS = 8
	)
	(
	input clk,    // Clock
	input rst_n,  // Asynchronous reset active low
	input [DATA_WIDTH-1:0] data_i,
	input write_en_i,
	input read_en_i,
	input [ADDR_WIDTH-1:0] write_addr_i,
	input [ADDR_WIDTH*NUM_PORTS-1:0] read_addr_i,
	output [DATA_WIDTH*NUM_PORTS-1:0] data_o
);
integer k;
genvar i;
localparam MEM_SIZE = 2**ADDR_WIDTH;

reg [DATA_WIDTH-1:0] mem [0:MEM_SIZE-1];
wire [ADDR_WIDTH-1:0] read_addr [0:NUM_PORTS-1];

generate
    for (i = 0; i < NUM_PORTS; i = i + 1) begin:convert_2d_1d_in
        
        assign read_addr[i] = read_addr_i[ADDR_WIDTH*i+ADDR_WIDTH-1:ADDR_WIDTH*i];
        assign data_o[DATA_WIDTH*i+DATA_WIDTH-1:DATA_WIDTH*i] = mem[read_addr[i]];
    end
endgenerate

always @(posedge clk) begin : proc_mem
	if (write_en_i)
		mem[write_addr_i] <= data_i;
end

endmodule

