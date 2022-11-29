//==================================================================================================
//  Filename      : gerenciador_memorias_acesso_externo.v
//  Created On    : 2022-10-06 07:29:50
//  Last Modified : 2022-11-29 07:50:30
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
			RELACOES_DATA_WIDTH = 8,
			NUM_PORTS = 8
		)
		(/*autoport*/
			input clk,
			input rst_n,
			//lendo relações
			// input relacoes_rd_enable_in,
			// input [ADDR_WIDTH-1:0] relacoes_rd_addr_in,
			// output [RELACOES_DATA_WIDTH-1:0] relacoes_rd_data_out,
			input [ADDR_WIDTH*NUM_PORTS-1:0] relacoes_read_addr_in,
			output [RELACOES_DATA_WIDTH*NUM_PORTS-1:0] relacoes_read_data_out,
			//escrevendo obstaculos
			input obstaculos_wr_enable_in,
			input [ADDR_WIDTH-1:0] obstaculos_wr_addr_in,
			input obstaculos_wr_data_in,
			//lendo obstaculos
			input [ADDR_WIDTH*NUM_PORTS-1:0] obstaculos_read_addr_in,
			output [NUM_PORTS-1:0] obstaculos_read_data_out
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


dual_port_ram_8 
	#(
		.DATA_WIDTH(RELACOES_DATA_WIDTH),
		.ADDR_WIDTH(ADDR_WIDTH),
		.NUM_PORTS(NUM_PORTS)
	)
	mem_relacoes
	(
		.clk(clk),
		.rst_n(rst_n),
		.data_i(),
		.write_en_i(1'b0),
		.write_addr_i(),
		.read_addr_i(relacoes_read_addr_in),
		.data_o(relacoes_read_data_out)
	);

dual_port_ram_8 
	#(
		.DATA_WIDTH(1),
		.ADDR_WIDTH(ADDR_WIDTH),
		.NUM_PORTS(NUM_PORTS)
	)
	mem_obstaculos
	(
		.clk(clk),
		.rst_n(rst_n),
		.data_i(obstaculos_wr_data_in),
		.write_en_i(obstaculos_wr_enable_in),
		.write_addr_i(obstaculos_wr_addr_in),
		.read_addr_i(obstaculos_read_addr_in),
		.data_o(obstaculos_read_data_out)
	);

endmodule