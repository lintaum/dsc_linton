//==================================================================================================
//  Filename      : localizador_vizinhos_validos8.v
//  Created On    : 2022-11-22 10:07:48
//  Last Modified : 2022-11-22 10:25:10
//  Revision      : 
//  Author        : Linton Esteves
//  Company       : UFBA
//  Email         : lintonthiago@gmail.com
//
//  Description   : 
//
//
//==================================================================================================
module localizador_vizinhos_validos8
            #(
                  parameter ADDR_WIDTH = 10,
                  parameter DISTANCIA_WIDTH = 6,
                  parameter MAX_VIZINHOS = 8,
                  parameter NUM_NA = 4,
                  parameter CUSTO_WIDTH = 4,
                  parameter UMA_RELACAO_WIDTH = ADDR_WIDTH+CUSTO_WIDTH,
                  parameter RELACOES_DATA_WIDTH = MAX_VIZINHOS*(UMA_RELACAO_WIDTH)
            )
            (/*autoport*/
                input clk,
                input rst_n,
                input aa_ocupado_in,
                input aa_pronto_in,
                input [NUM_NA-1:0] aa_aprovado_in,
                input [ADDR_WIDTH*NUM_NA-1:0] aa_endereco_in,
                input [ADDR_WIDTH*NUM_NA-1:0] aa_anterior_data_in,
                input [DISTANCIA_WIDTH*NUM_NA-1:0] aa_distancia_in,
                input cme_expandir_in,
                // Atualizando o avaliador de ativos
                output reg lvv_desativar_out,
                output reg lvv_atualizar_out,
                output reg [ADDR_WIDTH-1:0] lvv_endereco_out,
                output reg [ADDR_WIDTH-1:0] lvv_desativar_addr_out,
                output reg [CUSTO_WIDTH-1:0] lvv_menor_vizinho_out,
                output reg [DISTANCIA_WIDTH-1:0] lvv_distancia_out,
                output reg [ADDR_WIDTH-1:0] lvv_anterior_out,
                // Atualizando os estabelecidos
                output reg lvv_estabelecidos_write_en_out,
                output reg lvv_estabelecidos_write_data_out,
                output reg [ADDR_WIDTH-1:0] lvv_estabelecidos_write_addr_out,
                // Atualizando anterior
                output reg [ADDR_WIDTH-1:0] lvv_anterior_data_out,
                // Indicando que o processamento atual termninou
                output lvv_pronto_out,
                // Lendo relações
                output [ADDR_WIDTH-1:0] lvv_relacoes_read_addr0_out,
                output [ADDR_WIDTH-1:0] lvv_relacoes_read_addr1_out,
                output [ADDR_WIDTH-1:0] lvv_relacoes_read_addr2_out,
                output [ADDR_WIDTH-1:0] lvv_relacoes_read_addr3_out,
                output [ADDR_WIDTH-1:0] lvv_relacoes_read_addr4_out,
                output [ADDR_WIDTH-1:0] lvv_relacoes_read_addr5_out,
                output [ADDR_WIDTH-1:0] lvv_relacoes_read_addr6_out,
                output [ADDR_WIDTH-1:0] lvv_relacoes_read_addr7_out,
                input [RELACOES_DATA_WIDTH-1:0] gma_relacoes_read_data0_in,
                input [RELACOES_DATA_WIDTH-1:0] gma_relacoes_read_data1_in,
                input [RELACOES_DATA_WIDTH-1:0] gma_relacoes_read_data2_in,
                input [RELACOES_DATA_WIDTH-1:0] gma_relacoes_read_data3_in,
                input [RELACOES_DATA_WIDTH-1:0] gma_relacoes_read_data4_in,
                input [RELACOES_DATA_WIDTH-1:0] gma_relacoes_read_data5_in,
                input [RELACOES_DATA_WIDTH-1:0] gma_relacoes_read_data6_in,
                input [RELACOES_DATA_WIDTH-1:0] gma_relacoes_read_data7_in,
                // Lendo obstáculos
                output [ADDR_WIDTH-1:0] lvv_obstaculos_read_addr0_out,
                output [ADDR_WIDTH-1:0] lvv_obstaculos_read_addr1_out,
                output [ADDR_WIDTH-1:0] lvv_obstaculos_read_addr2_out,
                output [ADDR_WIDTH-1:0] lvv_obstaculos_read_addr3_out,
                output [ADDR_WIDTH-1:0] lvv_obstaculos_read_addr4_out,
                output [ADDR_WIDTH-1:0] lvv_obstaculos_read_addr5_out,
                output [ADDR_WIDTH-1:0] lvv_obstaculos_read_addr6_out,
                output [ADDR_WIDTH-1:0] lvv_obstaculos_read_addr7_out,
                input gma_obstaculos_read_data0_in,
                input gma_obstaculos_read_data1_in,
                input gma_obstaculos_read_data2_in,
                input gma_obstaculos_read_data3_in,
                input gma_obstaculos_read_data4_in,
                input gma_obstaculos_read_data5_in,
                input gma_obstaculos_read_data6_in,
                input gma_obstaculos_read_data7_in,
                //lendo estabelecidos
                output [ADDR_WIDTH-1:0] lvv_estabelecidos_read_addr0_out,
                output [ADDR_WIDTH-1:0] lvv_estabelecidos_read_addr1_out,
                output [ADDR_WIDTH-1:0] lvv_estabelecidos_read_addr2_out,
                output [ADDR_WIDTH-1:0] lvv_estabelecidos_read_addr3_out,
                output [ADDR_WIDTH-1:0] lvv_estabelecidos_read_addr4_out,
                output [ADDR_WIDTH-1:0] lvv_estabelecidos_read_addr5_out,
                output [ADDR_WIDTH-1:0] lvv_estabelecidos_read_addr6_out,
                output [ADDR_WIDTH-1:0] lvv_estabelecidos_read_addr7_out,
                input ge_read_data0_in,
                input ge_read_data1_in,
                input ge_read_data2_in,
                input ge_read_data3_in,
                input ge_read_data4_in,
                input ge_read_data5_in,
                input ge_read_data6_in,
                input ge_read_data7_in
        );

//*******************************************************
//Outputs
//*******************************************************
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        lvv_desativar_out <= 1'b0;
        lvv_atualizar_out <= 1'b0;
        lvv_endereco_out <= {ADDR_WIDTH{1'b0}};
        lvv_desativar_addr_out <= {ADDR_WIDTH{1'b0}};
        lvv_menor_vizinho_out <= {CUSTO_WIDTH{1'b0}};
        lvv_anterior_out <= {ADDR_WIDTH{1'b0}};
        lvv_distancia_out <= {DISTANCIA_WIDTH{1'b0}};
        lvv_pronto <= 1'b0;
    end
    else begin
        
    end
end

endmodule 