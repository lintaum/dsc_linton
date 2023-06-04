//==================================================================================================
//  Filename      : cae.v
//  Created On    : 2022-08-30 07:30:13
//  Last Modified : 2023-01-11 14:49:06
//  Revision      : 
//  Author        : Linton Esteves
//  Company       : UFBA
//  Email         : lintonthiago@gmail.com
//
//  Description   : 
//	Módulo controlador de acesso externo
//
//==================================================================================================
`include "../defines.vh"
module cae
		#(
            parameter ADDR_WIDTH = `ADDR_WIDTH,
            parameter AV_DATA_WIDTH = 32,
            parameter AV_ADDR_WIDTH = 32
		)
		(/*autoport*/
			input clk,
			input rst_n,
			// input remover_aprovados_in,
			input [AV_DATA_WIDTH-1:0] data_in,
			input [AV_ADDR_WIDTH-1:0] addr_in,
			output [AV_DATA_WIDTH-1:0] data_out,
			input write_enable,
			input read_enable
		);
//*******************************************************
//Internal
//*******************************************************
//Local Parameters
localparam BASE_FONTE = 0;
localparam BASE_DESTINO = 1;
localparam BASE_GMA_ = 2;
localparam BASE_GMA = 2;
localparam BASE_OBSTACULO = 1024;

//Wires
wire [ADDR_WIDTH-1:0] top_addr_fonte;
wire [ADDR_WIDTH-1:0] top_addr_destino;
wire top_wr_fonte;
wire top_wr_destino;
//lendo os resultados
wire [ADDR_WIDTH-1:0] gma_read_data;
wire gma_pronto;
//escrevendo os obstaculos
wire obstaculos_wr_enable;
wire [ADDR_WIDTH-1:0] obstaculos_wr_addr;
wire obstaculos_wr_data;

assign top_addr_fonte = data_in;
assign top_addr_destino = data_in;
assign obstaculos_wr_data = data_in;
// assign top_addr_destino = data_in;

assign obstaculos_wr_addr = addr_in;

assign top_wr_fonte = addr_in == BASE_FONTE && write_enable;
assign top_wr_destino = addr_in == BASE_DESTINO && write_enable;
assign obstaculos_wr_enable = addr_in >= BASE_OBSTACULO && write_enable;

assign data_out = addr_in == BASE_FONTE ? gma_pronto : gma_read_data;

//General Purpose Signals
//*******************************************************
top top_u0
	(
		.ADDR_WIDTH(`ADDR_WIDTH),
		.DISTANCIA_WIDTH(`DISTANCIA_WIDTH),
		.CRITERIO_WIDTH(DISTANCIA_WIDTH + 1),
		.CUSTO_WIDTH(`CUSTO_WIDTH),
		.MAX_VIZINHOS(`MAX_VIZINHOS),
		.UMA_RELACAO_WIDTH(ADDR_WIDTH+CUSTO_WIDTH),
		.RELACOES_DATA_WIDTH(MAX_VIZINHOS*(UMA_RELACAO_WIDTH)),
		.NUM_NA(`MAX_ATIVOS),
		.NUM_READ_PORTS(8),
		.NUM_EA(8),
		.NUM_PORTS(8)
     )
    (
        .clk(clk),
        .rst_n(rst_n),
        .top_addr_fonte_in(top_addr_fonte),
        .top_addr_destino_in(top_addr_destino),
        .top_wr_fonte_in(top_wr_fonte),
        .gma_read_data_out(gma_read_data),
        .gma_pronto_out(gma_pronto),
        .obstaculos_wr_enable_in(obstaculos_wr_enable),
        .obstaculos_wr_addr_in(obstaculos_wr_addr),
        .obstaculos_wr_data_in(obstaculos_wr_data)
    );

endmodule