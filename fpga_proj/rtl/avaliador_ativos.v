//==================================================================================================
//  Filename      : avaliador de ativos.v
//  Created On    : 2021-08-12 13:51:49
//  Last Modified : 2022-04-01 14:16:38
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
			parameter DIST_WIDTH = 8,
			parameter NODE_WIDTH = 8,
			parameter NUM_VIZINHOS = 8,
			parameter CUSTO_WIDTH = 8,
			parameter BUFFER_SIZE = 16
				
		)
		(/*autoport*/
			input clk_in,
			input rst_n_in,
			// Escrevendo ou atualizando um nó a ser analizado
			input escrever_in,
			input [DIST_WIDTH-1:0] ativar_distancia_in,
			input [DIST_WIDTH-1:0] ativar_menor_vizinho_in,
			input [NODE_WIDTH-1:0] ativar_endereco_no_in,
			// Removendo nó já estabelecido
			input remover_in,
			input [NODE_WIDTH-1:0] remover_endereco_no_in,
			// Indicando se existem nós ativos
			output tem_ativo
			// Indicando os nós aprovados
			output [BUFFER_SIZE-1:0] aprovados_out,
			// Lê a distância de um nó
			input ler_distancia,
			input [NODE_WIDTH-1:0] ler_distancia_endereco,
			output [DIST_WIDTH-1:0] distancia_out
			
		);
//*******************************************************
//Internal
//*******************************************************
//Local Parameters
//Wires
wire [DIST_WIDTH-1:0] criterio_out, treshold
wire [BUFFER_SIZE-1:0] endereco_escrita;
wire [BUFFER_SIZE-1:0] endereco_leitura;
wire [BUFFER_SIZE-1:0] endereco_remocao;
//Registers
reg [DIST_WIDTH-1:0] distancia [0:BUFFER_SIZE-1];
reg [DIST_WIDTH-1:0] menor_vizinho [0:BUFFER_SIZE-1];
reg [NODE_WIDTH-1:0] endereco [0:BUFFER_SIZE-1];
reg ativo [0:BUFFER_SIZE-1];

//*******************************************************
//Inserindo um novo nó ativo
//*******************************************************

always @(posedge clk_in or negedge rst_n_in) begin
	if (!rst_n_in) begin
		for (i = 0; i < BUFFER_SIZE; i = i + 1)begin
            distancia[i] <= {DIST_WIDTH{1'b0}};
            menor_vizinho[i] <= {DIST_WIDTH{1'b0}};
            endereco[i] <= {DIST_WIDTH{1'b0}};
            ativo[i] <= {DIST_WIDTH{1'b0}};
        end
	end
	else begin
		if (escrever_in) begin
			distancia[endereco_escrita] <= ativar_distancia_in;
            menor_vizinho[endereco_escrita] <= ativar_menor_vizinho_in;
            endereco[endereco_escrita] <= ativar_endereco_no_in;
            ativo[endereco_escrita] <= 1'b1;
		end
		
		if (remover_in) begin
			ativo[endereco_remocao] <= 1'b0;
		end
	end
end


generate
	genvar i;
	for (i = 0; i < BUFFER_SIZE; i = i + 1) begin:sum_criterio_out
		assign endereco_escrita[i] = endereco[i] == ativar_endereco_no_in
	end
endgenerate

//*******************************************************
//General Purpose Signals
//*******************************************************
generate
	genvar i;
	for (i = 0; i < BUFFER_SIZE; i = i + 1) begin:sum_criterio_out
		assign criterio_out[i] = menor_vizinho[i] + distancia[i]
	end
endgenerate


//*******************************************************
//Outputs
//*******************************************************
generate
	genvar i;
	for (i = 0; i < BUFFER_SIZE; i = i + 1) begin:aprovados
		assign aprovados_out[i] = criterio_out[i] <= treshold
	end
endgenerate
//*******************************************************
//Instantiations
//*******************************************************


endmodule