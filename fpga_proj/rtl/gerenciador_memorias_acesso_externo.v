//==================================================================================================
//  Filename      : gerenciador_memorias_acesso_externo.v
//  Created On    : 2022-10-06 07:29:50
//  Last Modified : 2022-11-22 10:16:32
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
			//lendo relações
			// input relacoes_rd_enable_in,
			// input [ADDR_WIDTH-1:0] relacoes_rd_addr_in,
			// output [RELACOES_DATA_WIDTH-1:0] relacoes_rd_data_out,
			input [ADDR_WIDTH-1:0] relacoes_read_addr0_in,
			input [ADDR_WIDTH-1:0] relacoes_read_addr1_in,
			input [ADDR_WIDTH-1:0] relacoes_read_addr2_in,
			input [ADDR_WIDTH-1:0] relacoes_read_addr3_in,
			input [ADDR_WIDTH-1:0] relacoes_read_addr4_in,
			input [ADDR_WIDTH-1:0] relacoes_read_addr5_in,
			input [ADDR_WIDTH-1:0] relacoes_read_addr6_in,
			input [ADDR_WIDTH-1:0] relacoes_read_addr7_in,
			output [RELACOES_DATA_WIDTH-1:0] relacoes_read_data0_out,
			output [RELACOES_DATA_WIDTH-1:0] relacoes_read_data1_out,
			output [RELACOES_DATA_WIDTH-1:0] relacoes_read_data2_out,
			output [RELACOES_DATA_WIDTH-1:0] relacoes_read_data3_out,
			output [RELACOES_DATA_WIDTH-1:0] relacoes_read_data4_out,
			output [RELACOES_DATA_WIDTH-1:0] relacoes_read_data5_out,
			output [RELACOES_DATA_WIDTH-1:0] relacoes_read_data6_out,
			output [RELACOES_DATA_WIDTH-1:0] relacoes_read_data7_out,
			//escrevendo obstaculos
			input obstaculos_wr_enable_in,
			input [ADDR_WIDTH-1:0] obstaculos_wr_addr_in,
			input obstaculos_wr_data_in,
			//lendo obstaculos
			input [ADDR_WIDTH-1:0] obstaculos_read_addr0_in,
			input [ADDR_WIDTH-1:0] obstaculos_read_addr1_in,
			input [ADDR_WIDTH-1:0] obstaculos_read_addr2_in,
			input [ADDR_WIDTH-1:0] obstaculos_read_addr3_in,
			input [ADDR_WIDTH-1:0] obstaculos_read_addr4_in,
			input [ADDR_WIDTH-1:0] obstaculos_read_addr5_in,
			input [ADDR_WIDTH-1:0] obstaculos_read_addr6_in,
			input [ADDR_WIDTH-1:0] obstaculos_read_addr7_in,
			output obstaculos_read_data0_out,
			output obstaculos_read_data1_out,
			output obstaculos_read_data2_out,
			output obstaculos_read_data3_out,
			output obstaculos_read_data4_out,
			output obstaculos_read_data5_out,
			output obstaculos_read_data6_out,
			output obstaculos_read_data7_out
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
		.ADDR_WIDTH(ADDR_WIDTH)
	)
	mem_relacoes
	(
		.clk(clk),
		.rst_n(rst_n),
		.data_i(),
		.write_en_i(1'b0),
		.write_addr_i(),
		.read_addr0_i(relacoes_read_addr0_in),
		.read_addr1_i(relacoes_read_addr1_in),
		.read_addr2_i(relacoes_read_addr2_in),
		.read_addr3_i(relacoes_read_addr3_in),
		.read_addr4_i(relacoes_read_addr4_in),
		.read_addr5_i(relacoes_read_addr5_in),
		.read_addr6_i(relacoes_read_addr6_in),
		.read_addr7_i(relacoes_read_addr7_in),
		.data0_o(relacoes_read_data0_out),
		.data1_o(relacoes_read_data1_out),
		.data2_o(relacoes_read_data2_out),
		.data3_o(relacoes_read_data3_out),
		.data4_o(relacoes_read_data4_out),
		.data5_o(relacoes_read_data5_out),
		.data6_o(relacoes_read_data6_out),
		.data7_o(relacoes_read_data7_out)
	);

dual_port_ram_8 
	#(
		.DATA_WIDTH(1),
		.ADDR_WIDTH(ADDR_WIDTH)
	)
	mem_obstaculos
	(
		.clk(clk),
		.rst_n(rst_n),
		.data_i(obstaculos_wr_data_in),
		.write_en_i(obstaculos_wr_enable_in),
		.write_addr_i(obstaculos_wr_addr_in),
		.read_addr0_i(obstaculos_read_addr0_in),
		.read_addr1_i(obstaculos_read_addr1_in),
		.read_addr2_i(obstaculos_read_addr2_in),
		.read_addr3_i(obstaculos_read_addr3_in),
		.read_addr4_i(obstaculos_read_addr4_in),
		.read_addr5_i(obstaculos_read_addr5_in),
		.read_addr6_i(obstaculos_read_addr6_in),
		.read_addr7_i(obstaculos_read_addr7_in),
		.data0_o(obstaculos_read_data0_out),
		.data1_o(obstaculos_read_data1_out),
		.data2_o(obstaculos_read_data2_out),
		.data3_o(obstaculos_read_data3_out),
		.data4_o(obstaculos_read_data4_out),
		.data5_o(obstaculos_read_data5_out),
		.data6_o(obstaculos_read_data6_out),
		.data7_o(obstaculos_read_data7_out)
	);

endmodule