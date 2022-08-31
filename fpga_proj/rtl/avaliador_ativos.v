//==================================================================================================
//  Filename      : avaliador_ativos.v
//  Created On    : 2022-08-30 10:13:25
//  Last Modified : 2022-08-31 11:05:22
//  Revision      : 
//  Author        : Linton Esteves
//  Company       : UFBA
//  Email         : lintonthiago@gmail.com
//
//  Description   : 
//
//
//==================================================================================================
module avaliador_ativos
		#(
      parameter NUM_NA = 8,
      parameter ADR_WIDTH = 5,
      parameter DISTANCIA_WIDTH = 5,
      parameter CRITERIO_WIDTH = 5,
      parameter CUSTO_WIDTH = 4
		)
		(/*autoport*/
			input clk,
			input rst_n,
      input desativar_in,
      input atualizar_in,
      input [ADR_WIDTH-1:0] endereco_in,
      input [CUSTO_WIDTH-1:0] menor_vizinho_in,
      input [DISTANCIA_WIDTH-1:0] distancia_in,
      input [ADR_WIDTH-1:0] anterior_in,
      output [NUM_NA-1:0] aa_aprovado_out,
      output [ADR_WIDTH*NUM_NA-1:0] aa_endereco_out,
			output [DISTANCIA_WIDTH*NUM_NA-1:0] aa_distancia_out
		);
//*******************************************************
//Internal
//*******************************************************
//Local Parameters
genvar i;
//Wires
// no_ativo
wire [ADR_WIDTH-1:0] na_endereco_2d [NUM_NA-1:0];
wire [DISTANCIA_WIDTH-1:0] na_distancia_2d [NUM_NA-1:0];
wire [NUM_NA-1:0] na_atualizar_anterior;
wire [ADR_WIDTH-1:0] na_anterior_2d [NUM_NA-1:0];
wire [CRITERIO_WIDTH-1:0] na_criterio_2d [NUM_NA-1:0];
wire [CRITERIO_WIDTH*NUM_NA-1:0] na_criterio_1d;
wire [NUM_NA-1:0] na_ativo;
wire [NUM_NA-1:0] na_nova_menor_distancia;
// gerenciador_ativos
wire [ADR_WIDTH-1:0] ga_endereco;
wire [NUM_NA-1:0] ga_habilitar;
wire [ADR_WIDTH-1:0] ga_anterior;
wire [CUSTO_WIDTH-1:0] ga_menor_vizinho;
wire [DISTANCIA_WIDTH-1:0] ga_distancia;
wire ga_atualizar;
wire ga_desativar;
// classificador_ativos
wire [CRITERIO_WIDTH-1:0] ca_criterio_geral;
// avaliador ativos
wire aa_atualizar_classificacao;
//Registers

//*******************************************************
//General Purpose Signals
//*******************************************************
// convertendo endereco 2d para 1d
generate
    for (i = 0; i < NUM_NA; i = i + 1) begin:convert_dimension_in
        assign aa_endereco_out[ADR_WIDTH*i+ADR_WIDTH-1:ADR_WIDTH*i] = na_endereco_2d[i];
        assign na_criterio_1d[CRITERIO_WIDTH*i+CRITERIO_WIDTH-1:CRITERIO_WIDTH*i] = na_criterio_2d[i];
        assign aa_distancia_out[DISTANCIA_WIDTH*i+DISTANCIA_WIDTH-1:DISTANCIA_WIDTH*i] = na_distancia_2d[i];
    end
endgenerate
//*******************************************************
//Outputs
//*******************************************************

//*******************************************************
//Instantiations
//*******************************************************
gerenciador_ativos
	#(
        .NUM_NA(NUM_NA),
        .ADR_WIDTH(ADR_WIDTH),
        .DISTANCIA_WIDTH(DISTANCIA_WIDTH),
        .CUSTO_WIDTH(CUSTO_WIDTH)      
    )
    gerenciador_ativos_u0
    (/*autoport*/
        .clk(clk),
        .rst_n(rst_n),
        .desativar_in(desativar_in),
        .atualizar_in(atualizar_in),
        .endereco_in(endereco_in),
        .anterior_in(anterior_in),
        .na_endereco_in(aa_endereco_out),
        .na_ativo_in(na_ativo),
        .menor_vizinho_in(menor_vizinho_in),
        .distancia_in(distancia_in),
        .ga_anterior_out(ga_anterior),
        .ga_atualizar_out(ga_atualizar),
        .ga_endereco_out(ga_endereco),
        .ga_desativar_out(ga_desativar),
        .ga_habilitar_out(ga_habilitar),
        .ga_menor_vizinho_out(ga_menor_vizinho),
        .ga_distancia_out(ga_distancia)
    );

generate

  for (i = 0; i < NUM_NA; i = i + 1) begin:gen_na
    no_ativo
    #(
      .ADR_WIDTH(ADR_WIDTH),
      .DISTANCIA_WIDTH(DISTANCIA_WIDTH),
      .CRITERIO_WIDTH(CRITERIO_WIDTH),
      .CUSTO_WIDTH(CUSTO_WIDTH)      
    )
    no_ativo_u0
    (/*autoport*/
      .clk(clk),
      .rst_n(rst_n),
      .menor_vizinho_in(ga_menor_vizinho),
      .distancia_in(ga_distancia),
      .ca_criterio_geral_in(ca_criterio_geral),
      .anterior_in(ga_anterior),
      .endereco_in(ga_endereco),
      .atualizar_in(ga_atualizar),
      .desativar_in(ga_desativar),
      .ga_habilitar_in(ga_habilitar[i]),
      .na_criterio_out(na_criterio_2d[i]),
      .na_distancia_out(na_distancia_2d[i]),
      .na_atualizar_anterior_out(na_atualizar_anterior[i]),
      .na_anterior_out(na_anterior_2d[i]),
      .na_aprovado_out(aa_aprovado_out[i]),
      .na_endereco_out(na_endereco_2d[i]),
      .na_ativo_out(na_ativo[i]),
      .na_nova_menor_distancia_out(na_nova_menor_distancia[i])
    );
  end
endgenerate

assign aa_atualizar_classificacao = |na_nova_menor_distancia;

classificar_ativo
		#(
			.NUM_NA(NUM_NA),
      .ADR_WIDTH(ADR_WIDTH),
      .CRITERIO_WIDTH(CRITERIO_WIDTH)
		)
		classificar_ativo_u0
		(/*autoport*/
			.clk(clk),
			.rst_n(rst_n),
			.na_criterio_in(na_criterio_1d),
      .na_ativo_in(na_ativo),
			.ca_criterio_geral_out(ca_criterio_geral),
      .aa_atualizar_in(aa_atualizar_classificacao)
		);
endmodule