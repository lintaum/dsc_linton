//==================================================================================================
//  Filename      : avaliar.v
//  Created On    : 2021-08-12 13:51:49
//  Last Modified : 2022-04-01 08:53:01
//  Revision      : 
//  Author        : Linton Esteves
//  Company       : UFBA
//  Email         : linton.thiago@gmail.com
//
//  Description   : 
//
//
//==================================================================================================
module avaliador_ativos
		#(
			parameter NUM_ATIVOS = 24,
			parameter DIST_WIDTH = 8,
			parameter NODE_WIDTH = 8,
			parameter NUM_VIZINHOS = 8
			parameter CUSTO_WIDTH = 8
				
		)
		(/*autoport*/
			input clk_in,
			input rst_n_in,
			// Escrevendo ou atualizando um nó a ser analizado
			input ativar_in,
			input [DIST_WIDTH-1:0] ativar_distancia_in,
			input [DIST_WIDTH-1:0] ativar_menor_vizinho_in,
			input [NODE_WIDTH-1:0] ativar_endereco_no_in,
			// Removendo nó já estabelecido
			input remover_in,
			input [NODE_WIDTH-1:0] remover_endereco_no_in,
			// Indicando se existem nós ativos
			output tem_ativo
			// Indicando os nós aprovados
			output [NUM_ATIVOS-1:0] aprovados_out,
			// Lê a distância de um nó
			input ler_distancia,
			input [NODE_WIDTH-1:0] ler_distancia_endereco,
			output [DIST_WIDTH-1:0] distancia_out
			
		);
//*******************************************************
//Internal
//*******************************************************
//Local Parameters
wire [NODE_WIDTH-1:0] ativos [0:NUM_ATIVOS-1];
wire [DIST_WIDTH-1:0] distancia [0:NUM_ATIVOS-1];
wire [CUSTO_WIDTH-1:0] menor_vizinho [0:NUM_ATIVOS-1];
//Wires

//Registers
wire [DIST_WIDTH-1:0] criterio_out, treshold
reg [DIST_WIDTH-1:0] treshold_l1, treshold_l2,
//*******************************************************
//General Purpose Signals
//*******************************************************

generate
	genvar i;
	for (i = 0; i < NUM_ATIVOS; i = i + 1) begin:sum_criterio_out
		assign criterio_out[i] = menor_vizinho[i] + distancia[i]
	end
endgenerate



//*******************************************************
//Outputs
//*******************************************************
generate
	genvar i;
	for (i = 0; i < NUM_ATIVOS; i = i + 1) begin:aprovados
		assign aprovados_out[i] = criterio_out[i] <= treshold
	end
endgenerate
//*******************************************************
//Instantiations
//*******************************************************


endmodule