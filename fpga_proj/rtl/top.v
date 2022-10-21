//==================================================================================================
//  Filename      : top.v
//  Created On    : 2022-10-04 09:58:39
//  Last Modified : 2022-10-21 13:28:40
//  Revision      : 
//  Author        : Linton Esteves
//  Company       : UFBA
//  Email         : lintonthiago@gmail.com
//
//  Description   : 
//
//
//==================================================================================================
module top
        #(
            parameter ADDR_WIDTH = 10,
            parameter DISTANCIA_WIDTH = 6,
            parameter CRITERIO_WIDTH = DISTANCIA_WIDTH + 1,
            parameter CUSTO_WIDTH = 4,
            // parameter DATA_WIDTH = 8,
            parameter MAX_VIZINHOS = 8,
            parameter UMA_RELACAO_WIDTH = ADDR_WIDTH+CUSTO_WIDTH,
            parameter RELACOES_DATA_WIDTH = MAX_VIZINHOS*(UMA_RELACAO_WIDTH),
            parameter NUM_NA = 8
        )
        (/*autoport*/
            input clk,
            input rst_n,
            input [ADDR_WIDTH-1:0] top_addr_fonte_in,
            input [ADDR_WIDTH-1:0] top_addr_destino_in,
            input top_wr_fonte_in,
            output [ADDR_WIDTH-1:0] gma_read_data_out,
            output gma_pronto_out
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
     cme_construir_caminho;

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
//sinais de saida do lvv
wire lvv_desativar;
wire lvv_atualizar;
wire [ADDR_WIDTH-1:0] lvv_anterior_data;
wire [ADDR_WIDTH-1:0] lvv_endereco;
wire [CUSTO_WIDTH-1:0] lvv_menor_vizinho;
wire [DISTANCIA_WIDTH-1:0] lvv_distancia;
wire [ADDR_WIDTH-1:0] lvv_anterior;
wire lvv_relacoes_rd_enable;
wire [ADDR_WIDTH-1:0] lvv_relacoes_rd_addr;
wire lvv_obstaculos_rd_enable;
wire [ADDR_WIDTH-1:0] lvv_obstaculos_rd_addr;
wire lvv_estabelecidos_write_en;
wire lvv_estabelecidos_write_data;
wire [ADDR_WIDTH-1:0] lvv_estabelecidos_write_addr;
wire lvv_estabelecidos_read_en;
wire [ADDR_WIDTH-1:0] lvv_estabelecidos_read_addr;
//sinais de saida do gma
wire [RELACOES_DATA_WIDTH-1:0] gma_relacoes_rd_data;
wire gma_obstaculos_rd_data;
wire lvv_pronto;

// sinais de controle do top
wire [ADDR_WIDTH-1:0] endereco_mix;
wire atualizar_mix;
wire [CUSTO_WIDTH-1:0] menor_vizinho_mix;
wire [DISTANCIA_WIDTH-1:0] distancia_mix;
//Registers
reg [ADDR_WIDTH-1:0] fonte, destino;
//*******************************************************
//General Purpose Signals
//*******************************************************
assign atualizar_mix = top_wr_fonte_in ? 1'b1: lvv_atualizar;
assign endereco_mix = top_wr_fonte_in ? top_addr_fonte_in: lvv_endereco;
assign menor_vizinho_mix = top_wr_fonte_in ? 0: lvv_menor_vizinho;
assign distancia_mix = top_wr_fonte_in ? 0: lvv_distancia;

// Salvando a fonte e o destino
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        fonte <= {ADDR_WIDTH{1'b0}};
        destino <= {ADDR_WIDTH{1'b0}};
    end
    else begin
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
            .write_en_in(lvv_estabelecidos_write_en),
            .write_data_in(lvv_estabelecidos_write_data),
            .write_addr_in(lvv_estabelecidos_write_addr),
            .read_en0_in(lvv_estabelecidos_read_en),
            .read_en1_in(),
            .read_addr0_in(lvv_estabelecidos_read_addr),
            .read_addr1_in(),
            .read_data0_out(ge_read_data0_out),
            .read_data1_out(ge_read_data1_out)
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
            .relacoes_rd_enable_in(lvv_relacoes_rd_enable),
            .relacoes_rd_addr_in(lvv_relacoes_rd_addr),
            .relacoes_rd_data_out(gma_relacoes_rd_data),
            .obstaculos_rd_enable_in(lvv_obstaculos_rd_enable),
            .obstaculos_rd_addr_in(lvv_obstaculos_rd_addr),
            .obstaculos_rd_data_out(gma_obstaculos_rd_data)
        );

controlador_maquina_estados
    controlador_maquina_estados_U0
        (/*autoport*/
            .clk(clk),
            .rst_n(rst_n),
            .iniciar_in(top_wr_fonte_in),
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
            .atualizar_buffer_out(cme_atualizar_buffer),
            .construir_caminho_out(cme_construir_caminho)
        );

avaliador_ativos
        #(
            .NUM_NA(NUM_NA),
            .ADDR_WIDTH(ADDR_WIDTH),
            .DISTANCIA_WIDTH(DISTANCIA_WIDTH),
            .CRITERIO_WIDTH(CRITERIO_WIDTH),
            .CUSTO_WIDTH(CUSTO_WIDTH)
        )
        avaliador_ativos_u0
        (/*autoport*/
            .clk(clk),
            .rst_n(rst_n),
            .remover_aprovados_in(cme_atualizar_buffer),
            .lvv_pronto_in(lvv_pronto),
            .desativar_in(lvv_desativar),
            .atualizar_in(atualizar_mix),
            .endereco_in(endereco_mix),
            .menor_vizinho_in(menor_vizinho_mix),
            .distancia_in(distancia_mix),
            .anterior_in(lvv_anterior),
            .aa_aprovado_out(aa_aprovado),
            .aa_endereco_out(aa_endereco),
            .aa_distancia_out(aa_distancia),
            .aa_tem_aprovado_out(aa_tem_aprovado),
            .aa_ocupado_out(aa_ocupado),
            .aa_pronto_out(aa_pronto),
            .aa_anterior_data_out(aa_anterior_data),
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

localizador_vizinhos_validos
        #(
            .ADDR_WIDTH(ADDR_WIDTH),
            .MAX_VIZINHOS(MAX_VIZINHOS),
            .RELACOES_DATA_WIDTH(RELACOES_DATA_WIDTH),
            .NUM_NA(NUM_NA),
            .UMA_RELACAO_WIDTH(UMA_RELACAO_WIDTH),
            .DISTANCIA_WIDTH(DISTANCIA_WIDTH),
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
            // .aa_tem_ativo_in(aa_tem_ativo),
            // .aa_tem_aprovado_in(aa_tem_aprovado),
            .lvv_desativar_out(lvv_desativar),
            .lvv_atualizar_out(lvv_atualizar),
            .lvv_endereco_out(lvv_endereco),
            .lvv_menor_vizinho_out(lvv_menor_vizinho),
            .lvv_distancia_out(lvv_distancia),
            .lvv_anterior_out(lvv_anterior),
            .lvv_relacoes_rd_enable_out(lvv_relacoes_rd_enable),
            .lvv_relacoes_rd_addr_out(lvv_relacoes_rd_addr),
            .gma_relacoes_rd_data_in(gma_relacoes_rd_data),
            .lvv_obstaculos_rd_enable_out(lvv_obstaculos_rd_enable),
            .lvv_obstaculos_rd_addr_out(lvv_obstaculos_rd_addr),
            .gma_obstaculos_rd_data_in(gma_obstaculos_rd_data),
            .lvv_estabelecidos_write_en_out(lvv_estabelecidos_write_en),
            .lvv_estabelecidos_write_data_out(lvv_estabelecidos_write_data),
            .lvv_estabelecidos_write_addr_out(lvv_estabelecidos_write_addr),
            .lvv_estabelecidos_read_en_out(lvv_estabelecidos_read_en),
            .lvv_estabelecidos_read_addr_out(lvv_estabelecidos_read_addr),
            .ge_estabelecidos_read_data_in(ge_read_data0_out),
            .lvv_anterior_data_out(lvv_anterior_data),
            .lvv_pronto_out(lvv_pronto)
            
        );



endmodule