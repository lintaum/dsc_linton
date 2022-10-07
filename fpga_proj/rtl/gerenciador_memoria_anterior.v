//==================================================================================================
//  Filename      : gerenciador_memoria_anterior.v
//  Created On    : 2022-10-04 09:53:21
//  Last Modified : 2022-10-04 09:53:46
//  Revision      : 
//  Author        : Linton Esteves
//  Company       : UFBA
//  Email         : lintonthiago@gmail.com
//
//  Description   : 
//
//
//==================================================================================================
module gerenciador_memoria_anterior
		#(
			parameter DATA_WIDTH = 32,
			parameter ADDR_WIDTH = 10
		)
		(/*autoport*/
			input clk,    // Clock
			input rst_n,  // Asynchronous reset active low
			input [DATA_WIDTH-1:0] data_i,
			input write_en_i,
			input read_en_i,
			input [ADDR_WIDTH-1:0] read_addr_i,
			input [ADDR_WIDTH-1:0] write_addr_i,
			output [DATA_WIDTH-1:0] data_o
		);
//*******************************************************
//Internal
//*******************************************************
//Local Parameters

//Wires

//Registers

//*******************************************************
//General Purpose Signals
//*******************************************************

//*******************************************************
//Outputs
//*******************************************************

//*******************************************************
//Instantiations
//*******************************************************

dual_port_ram 
	#(
		.DATA_WIDTH(DATA_WIDTH),
		.ADDR_WIDTH(ADDR_WIDTH)
	)
	dual_port_ram_u0
	(
		.clk(clk),
		.rst_n(rst_n),
		.data_i(data_i),
		.write_en_i(write_en_i),
		.read_en_i(read_en_i),
		.read_addr_i(read_addr_i),
		.write_addr_i(write_addr_i),
		.data_o(data_o)
	);

endmodule