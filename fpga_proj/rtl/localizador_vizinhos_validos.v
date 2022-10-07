//==================================================================================================
//  Filename      : localizador_vizinhos_validos.v
//  Created On    : 2022-10-04 09:59:38
//  Last Modified : 2022-10-07 13:53:46
//  Revision      : 
//  Author        : Linton Esteves
//  Company       : UFBA
//  Email         : lintonthiago@gmail.com
//
//  Description   : 
//
//
//==================================================================================================
module localizador_vizinhos_validos
		#(
			ADDR_WIDTH = 8,
			RELACOES_DATA_WIDTH = 8,
			NUM_NA = 4,
	        DISTANCIA_WIDTH = 5,
	        CUSTO_WIDTH = 4,
	        DATA_WIDTH = 4
		)
		(/*autoport*/
			input clk,
			input rst_n,
			input [NUM_NA-1:0] aa_aprovado_in,
      		input [ADDR_WIDTH*NUM_NA-1:0] aa_endereco_in,
			input [DISTANCIA_WIDTH*NUM_NA-1:0] aa_distancia_in,
      		input aa_tem_ativo_in,
      		input aa_tem_aprovado_in,
      		input cme_expandir_in,
      		// Atualizando o avaliador de ativos
      		output lvv_desativar_out,
			output lvv_atualizar_out,
			output [ADDR_WIDTH-1:0] lvv_endereco_out,
			output [CUSTO_WIDTH-1:0] lvv_menor_vizinho_out,
			output [DISTANCIA_WIDTH-1:0] lvv_distancia_out,
			output [ADDR_WIDTH-1:0] lvv_anterior_out,
			// Lendo relações de um nó
			output lvv_relacoes_rd_enable_out,
			output [ADDR_WIDTH-1:0] lvv_relacoes_rd_addr_out,
			input [RELACOES_DATA_WIDTH-1:0] gma_relacoes_rd_data_in,
			// Lendo obstáculos
			output lvv_obstaculos_rd_enable_out,
			output [ADDR_WIDTH-1:0] lvv_obstaculos_rd_addr_out,
			input gma_obstaculos_rd_data_in,
			// Atualizando os estabelecidos
			output lvv_estabelecidos_write_en_out,
			output [DATA_WIDTH-1:0] lvv_estabelecidos_write_data_out,
			output [ADDR_WIDTH-1:0] lvv_estabelecidos_write_addr_out
			
		);
//*******************************************************
//Internal
//*******************************************************
//Local Parameters
genvar i;
//Wires
wire [ADDR_WIDTH-1:0] aa_endereco_2d [0:NUM_NA-1];
wire [DISTANCIA_WIDTH-1:0] aa_distancia_2d [0:NUM_NA-1];
//Registers

//*******************************************************
//General Purpose Signals
//*******************************************************
assign lvv_desativar_out = 0;
assign lvv_atualizar_out = 0;
assign lvv_endereco_out = 0;
assign lvv_menor_vizinho_out = 0;
assign lvv_distancia_out = 0;
assign lvv_anterior_out = 0;

//*******************************************************
// Convertendo entradas para 2d
//*******************************************************

//Convertendo entrada 1d para 2d
generate
    for (i = 0; i < NUM_NA; i = i + 1) begin:convert_dimension_in
		assign aa_endereco_2d[i] = aa_endereco_in[ADDR_WIDTH*i+ADDR_WIDTH-1:ADDR_WIDTH*i];
		assign aa_distancia_2d[i] = aa_distancia_in[DISTANCIA_WIDTH*i+DISTANCIA_WIDTH-1:DISTANCIA_WIDTH*i];
    end
endgenerate

//*******************************************************
//Outputs
//*******************************************************

//*******************************************************
//Instantiations
//*******************************************************

endmodule