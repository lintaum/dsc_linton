//==================================================================================================
//  Filename      : top.v
//  Created On    : 2022-10-04 09:58:39
//  Last Modified : 2023-01-19 13:18:32
//  Revision      : 
//  Author        : Linton Esteves
//  Company       : UFBA
//  Email         : lintonthiago@gmail.com
//
//  Description   : 
//
//
//==================================================================================================

`include "/home/linton/proj_dsc/dsc/defines.vh"

module top
        #(
            parameter ADDR_WIDTH = `ADDR_WIDTH,
            parameter DISTANCIA_WIDTH = `DISTANCIA_WIDTH,
            parameter CRITERIO_WIDTH = DISTANCIA_WIDTH + 1,
            parameter CUSTO_WIDTH = `CUSTO_WIDTH,
            parameter MAX_VIZINHOS = `MAX_VIZINHOS,
            parameter UMA_RELACAO_WIDTH = ADDR_WIDTH+CUSTO_WIDTH,
            parameter RELACOES_DATA_WIDTH = MAX_VIZINHOS*(UMA_RELACAO_WIDTH),
            parameter NUM_NA = `MAX_ATIVOS,
            parameter NUM_READ_PORTS = 8,
            parameter NUM_EA = 8,
            parameter NUM_PORTS = 8
        )
        (/*autoport*/
            input clk,
            input rst_n,
            input [ADDR_WIDTH-1:0] top_addr_fonte_in,
            input [ADDR_WIDTH-1:0] top_addr_destino_in,
            input top_wr_fonte_in,
            //lendo os resultados
            output [ADDR_WIDTH-1:0] gma_read_data_out,
            output gma_pronto_out,
            //escrevendo os obstaculos
            input obstaculos_wr_enable_in,
            input [ADDR_WIDTH-1:0] obstaculos_wr_addr_in,
            input obstaculos_wr_data_in
        );
//*******************************************************
//Internal
//*******************************************************
//Local Parameters

//Wires
//sinais de saida do cme
wire cme_aguardando,
     cme_caminho_pronto,
     cme_iniciar,
     cme_expandir,
     cme_atualizar_buffer,
     cme_construir_caminho,
     cme_atualizar_classificacao;

//sinais de saida do buffer aa
wire [NUM_NA-1:0] buff_aa_aprovado;
wire [ADDR_WIDTH*NUM_NA-1:0] buff_aa_endereco;
wire [DISTANCIA_WIDTH*NUM_NA-1:0] buff_aa_distancia;
//sinais de saida do aa
wire [NUM_NA-1:0] aa_aprovado;
wire [ADDR_WIDTH*NUM_NA-1:0] aa_endereco;
wire [DISTANCIA_WIDTH*NUM_NA-1:0] aa_distancia;
wire [ADDR_WIDTH*NUM_NA-1:0] aa_anterior_data;
wire aa_tem_ativo;
wire aa_tem_aprovado;
wire aa_ocupado;
wire aa_pronto;
wire aa_atualizar_ready;
//sinais de saida do lvv
wire lvv_desativar;
wire lvv_atualizar;
wire [ADDR_WIDTH-1:0] lvv_anterior_data;
wire [ADDR_WIDTH-1:0] lvv_endereco;
wire [CUSTO_WIDTH-1:0] lvv_menor_vizinho;
wire [DISTANCIA_WIDTH-1:0] lvv_distancia;
wire [ADDR_WIDTH-1:0] lvv_anterior;
wire [ADDR_WIDTH-1:0] lvv_relacoes_rd_addr;
wire [ADDR_WIDTH-1:0] lvv_obstaculos_rd_addr;
wire [ADDR_WIDTH*NUM_PORTS-1:0] lvv_estabelecidos_write_addr;
wire lvv_estabelecidos_read_en;
wire lvv_pronto;

wire lvv_aa_desativar;
wire lvv_aa_atualizar;
wire [NUM_READ_PORTS-1:0] lvv_aa_vizinho_valido;
wire [NUM_READ_PORTS*ADDR_WIDTH-1:0] lvv_aa_endereco;
wire [NUM_READ_PORTS*CUSTO_WIDTH-1:0] lvv_aa_menor_vizinho;
wire [NUM_READ_PORTS*DISTANCIA_WIDTH-1:0] lvv_aa_distancia;
wire [ADDR_WIDTH-1:0] lvv_aa_anterior;

wire [ADDR_WIDTH*NUM_PORTS-1:0] lvv_relacoes_read_addr;
wire [ADDR_WIDTH*NUM_PORTS-1:0] lvv_obstaculos_read_addr;
wire [ADDR_WIDTH*NUM_PORTS-1:0] lvv_estabelecidos_read_addr;

// sinais de saída do GE
wire [NUM_PORTS-1:0] ge_read_data;

//sinais de saida do gma
wire [RELACOES_DATA_WIDTH*NUM_PORTS-1:0] gma_relacoes_read_data;
wire [NUM_PORTS-1:0] gma_obstaculos_read_data;

// sinais de controle do top
// wire [ADDR_WIDTH-1:0] endereco_mix;
// wire atualizar_mix;
// wire [CUSTO_WIDTH-1:0] menor_vizinho_mix;
// wire [DISTANCIA_WIDTH-1:0] distancia_mix;
//Registers
reg [ADDR_WIDTH-1:0] fonte, destino;
reg top_wr_fonte_in_r;
//*******************************************************
//General Purpose Signals
//*******************************************************

// Salvando a fonte e o destino
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        fonte <= {ADDR_WIDTH{1'b0}};
        destino <= {ADDR_WIDTH{1'b0}};
        top_wr_fonte_in_r <= 1'b0;
    end
    else begin
        top_wr_fonte_in_r <= top_wr_fonte_in;
        if (top_wr_fonte_in) begin
            destino <= top_addr_destino_in;
            fonte <= top_addr_fonte_in;
        end
    end
end

//*******************************************************
//Outputs
//*******************************************************

//*******************************************************
//Instantiations
//*******************************************************

gerenciador_memoria_anterior
        #(
            .ADDR_WIDTH(ADDR_WIDTH)
        )
        gerenciador_memoria_anterior_u0
        (/*autoport*/
            .clk(clk),
            .rst_n(rst_n),
            .top_fonte_in(fonte),
            .top_destino_in(destino),
            .cme_construir_caminho_in(cme_construir_caminho),
            .write_en_in(lvv_estabelecidos_write_en),
            .write_data_in(lvv_anterior_data),
            .write_addr_in(lvv_estabelecidos_write_addr),
            .read_data_out(gma_read_data_out),
            .pronto_out(gma_pronto_out)
        );

gerenciador_estabelecidos
        #(
            .ADDR_WIDTH(ADDR_WIDTH)
        )
        gerenciador_estabelecidos_u0
        (/*autoport*/
            .clk(clk),
            .rst_n(rst_n),
            .soft_reset_n(!top_wr_fonte_in_r),
            .write_en_in(lvv_estabelecidos_write_en),
            .write_addr_in(lvv_estabelecidos_write_addr),
            .read_addr_in(lvv_estabelecidos_read_addr),
            .read_data_out(ge_read_data)
        );

gerenciador_memorias_acesso_externo
        #(
            .ADDR_WIDTH(ADDR_WIDTH),
            .RELACOES_DATA_WIDTH(RELACOES_DATA_WIDTH)
        )
        gerenciador_memorias_acesso_externo_u0
        (/*autoport*/
            .clk(clk),
            .rst_n(rst_n),
            .relacoes_read_addr_in(lvv_relacoes_read_addr),
            .relacoes_read_data_out(gma_relacoes_read_data),
            .obstaculos_read_addr_in(lvv_obstaculos_read_addr),
            .obstaculos_read_data_out(gma_obstaculos_read_data),
            .obstaculos_wr_enable_in(obstaculos_wr_enable_in),
            .obstaculos_wr_addr_in(obstaculos_wr_addr_in),
            .obstaculos_wr_data_in(obstaculos_wr_data_in)
        );

controlador_maquina_estados
    controlador_maquina_estados_U0
        (/*autoport*/
            .clk(clk),
            .rst_n(rst_n),
            .iniciar_in(top_wr_fonte_in_r),
            .tem_ativo_in(aa_tem_ativo),
            .lvv_pronto_in(lvv_pronto),
            .aa_pronto_in(aa_pronto),
            .aa_ocupado_in(aa_ocupado),
            .caminho_pronto_in(),
            .lido_in(),
            .aguardando_out(cme_aguardando),
            .caminho_pronto_out(cme_caminho_pronto),
            .iniciar_out(cme_iniciar),
            .expandir_out(cme_expandir),
            .atualizar_classificacao_out(cme_atualizar_classificacao),
            .atualizar_buffer_out(cme_atualizar_buffer),
            .construir_caminho_out(cme_construir_caminho)
        );

avaliador_ativos
        #(
            .NUM_NA(NUM_NA),
            .ADDR_WIDTH(ADDR_WIDTH),
            .DISTANCIA_WIDTH(DISTANCIA_WIDTH),
            .CRITERIO_WIDTH(CRITERIO_WIDTH),
            .NUM_EA(NUM_EA),
            .CUSTO_WIDTH(CUSTO_WIDTH)
        )
        avaliador_ativos_u0
        (/*autoport*/
            .clk(clk),
            .rst_n(rst_n),
            // .remover_aprovados_in(cme_atualizar_buffer),
            .lvv_pronto_in(lvv_pronto),
            
            .top_atualizar_fonte_in(top_wr_fonte_in_r),
            .top_endereco_fonte_in(fonte),

            .lvv_aa_desativar_in(lvv_aa_desativar),
            .lvv_aa_atualizar_in(lvv_aa_atualizar),
            .lvv_aa_vizinho_valido_in(lvv_aa_vizinho_valido),
            .lvv_aa_endereco_in(lvv_aa_endereco),
            .lvv_aa_menor_vizinho_in(lvv_aa_menor_vizinho),
            .lvv_aa_distancia_in(lvv_aa_distancia),
            .lvv_aa_anterior_in(lvv_aa_anterior),

            .cme_atualizar_classificacao_in(cme_atualizar_classificacao),
            .aa_aprovado_out(aa_aprovado),
            .aa_endereco_out(aa_endereco),
            .aa_distancia_out(aa_distancia),
            .aa_tem_aprovado_out(aa_tem_aprovado),
            .aa_ocupado_out(aa_ocupado),
            .aa_pronto_out(aa_pronto),
            .aa_anterior_data_out(aa_anterior_data),
            .aa_atualizar_ready_out(aa_atualizar_ready),
            .aa_tem_ativo_out(aa_tem_ativo)
        );

buffer
    #(
        .DATA_WIDTH(NUM_NA+ADDR_WIDTH*NUM_NA+DISTANCIA_WIDTH*NUM_NA)
    )
    buffer_aa
    (/*autoport*/
        .clk(clk),
        .rst_n(rst_n),
        .write_en_in(cme_atualizar_buffer),
        .data_in({aa_aprovado, aa_endereco, aa_distancia}),
        .data_out({buff_aa_aprovado, buff_aa_endereco, buff_aa_distancia})
    );

localizador_vizinhos_validos8
        #(
            .ADDR_WIDTH(ADDR_WIDTH),
            .MAX_VIZINHOS(MAX_VIZINHOS),
            .RELACOES_DATA_WIDTH(RELACOES_DATA_WIDTH),
            .NUM_NA(NUM_NA),
            .UMA_RELACAO_WIDTH(UMA_RELACAO_WIDTH),
            .DISTANCIA_WIDTH(DISTANCIA_WIDTH),
            .NUM_EA(NUM_EA),
            .CUSTO_WIDTH(CUSTO_WIDTH)
            // .DATA_WIDTH(DATA_WIDTH)
        )
        localizador_vizinhos_validos_u0
        (/*autoport*/
            .clk(clk),
            .rst_n(rst_n),
            .cme_expandir_in(cme_expandir),
            .aa_pronto_in(aa_pronto),
            .aa_ocupado_in(aa_ocupado),
            .aa_anterior_data_in(aa_anterior_data),
            .aa_aprovado_in(buff_aa_aprovado),
            .aa_endereco_in(buff_aa_endereco),
            .aa_distancia_in(buff_aa_distancia),
            .aa_atualizar_ready_in(aa_atualizar_ready),
            // .aa_tem_ativo_in(aa_tem_ativo),
            // .aa_tem_aprovado_in(aa_tem_aprovado),
            .lvv_desativar_out(lvv_aa_desativar),
            .lvv_atualizar_out(lvv_aa_atualizar),
            .lvv_vizinho_valido_out(lvv_aa_vizinho_valido),
            .lvv_endereco_out(lvv_aa_endereco),
            .lvv_menor_vizinho_out(lvv_aa_menor_vizinho),
            .lvv_distancia_out(lvv_aa_distancia),
            .lvv_anterior_out(lvv_aa_anterior),

            .lvv_estabelecidos_write_en_out(lvv_estabelecidos_write_en),
            .lvv_estabelecidos_write_addr_out(lvv_estabelecidos_write_addr),
            .lvv_anterior_data_out(lvv_anterior_data),
            .lvv_pronto_out(lvv_pronto),
            
            .lvv_relacoes_read_addr_out(lvv_relacoes_read_addr),
            .gma_relacoes_read_data_in(gma_relacoes_read_data),

            .lvv_obstaculos_read_addr_out(lvv_obstaculos_read_addr),
            .gma_obstaculos_read_data_in(gma_obstaculos_read_data),

            .lvv_estabelecidos_read_addr_out(lvv_estabelecidos_read_addr),       
            .ge_read_data_in(ge_read_data)
        );


endmodule