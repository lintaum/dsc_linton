//==================================================================================================
//  Filename      : gerenciador_memorias_acesso_externo.v
//  Created On    : 2022-10-06 07:29:50
//  Last Modified : 2022-10-06 08:15:07
//  Revision      : 
//  Author        : Linton Esteves
//  Company       : UFBA
//  Email         : lintonthiago@gmail.com
//
//  Description   : 
//
//
//==================================================================================================
module gerenciador_memorias_acesso_externo
		#(
			ADDR_WIDTH = 8,
			RELACOES_DATA_WIDTH = 8
		)
		(/*autoport*/
			input clk,
			input rst_n,

			input relacoes_rd_enable_in,
			input [ADDR_WIDTH-1:0] relacoes_rd_addr_in,
			output [RELACOES_DATA_WIDTH-1:0] relacoes_rd_data_out,

			input obstaculos_rd_enable_in,
			input [ADDR_WIDTH-1:0]obstaculos_rd_addr_in,
			output obstaculos_rd_data_out
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
		.DATA_WIDTH(RELACOES_DATA_WIDTH),
		.ADDR_WIDTH(ADDR_WIDTH)
	)
	mem_relacoes
	(
		.clk(clk),
		.rst_n(rst_n),
		.data_i(),
		.write_en_i(1'b0),
		.read_en_i(relacoes_rd_enable_in),
		.read_addr_i(relacoes_rd_addr_in),
		.write_addr_i(),
		.data_o(relacoes_rd_data_out)
	);

dual_port_ram 
	#(
		.DATA_WIDTH(1),
		.ADDR_WIDTH(ADDR_WIDTH)
	)
	mem_obstaculos
	(
		.clk(clk),
		.rst_n(rst_n),
		.data_i(),
		.write_en_i(1'b0),
		.read_en_i(obstaculos_rd_enable_in),
		.read_addr_i(obstaculos_rd_addr_in),
		.write_addr_i(),
		.data_o(obstaculos_rd_data_out)
	);
endmodule