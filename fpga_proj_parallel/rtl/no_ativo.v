//==================================================================================================
//  Filename      : no_ativo.v
//  Created On    : 2022-08-30 07:30:13
//  Last Modified : 2023-01-11 14:49:06
//  Revision      : 
//  Author        : Linton Esteves
//  Company       : UFBA
//  Email         : lintonthiago@gmail.com
//
//  Description   : 
//
//
//==================================================================================================
module no_ativo
		#(
            parameter ADDR_WIDTH = 5,
            parameter DISTANCIA_WIDTH = 5,
            parameter CRITERIO_WIDTH = 5,
            parameter CUSTO_WIDTH = 4
		)
		(/*autoport*/
			input clk,
			input rst_n,
			// input remover_aprovados_in,
			input [CUSTO_WIDTH-1:0] menor_vizinho_in,
			input [DISTANCIA_WIDTH-1:0] distancia_in,
			input [CRITERIO_WIDTH-1:0] ca_criterio_geral_in,
			input [ADDR_WIDTH-1:0] endereco_in,
			input [ADDR_WIDTH-1:0] anterior_in,
			input atualizar_in,
			input desativar_in,
			input ga_habilitar_in,
			output reg [CRITERIO_WIDTH-1:0] na_criterio_out,
			output reg [DISTANCIA_WIDTH-1:0] na_distancia_out,
			output reg [ADDR_WIDTH-1:0] na_anterior_out,
			output reg na_aprovado_out,
			output reg [ADDR_WIDTH-1:0] na_endereco_out,
			output reg na_ativo_out
		);
//*******************************************************
//Internal
//*******************************************************
//Local Parameters

//Wires

wire ativar, atualizar; 
wire nova_menor_distancia; 
wire aprovado;
// wire desativar;
wire desativar_aprovado;
//Registers
reg [CUSTO_WIDTH-1:0] menor_vizinho_r;
//General Purpose Signals
//*******************************************************
assign ativar = (atualizar_in & !na_ativo_out) & ga_habilitar_in;
// assign desativar = desativar_in & aprovado;
// assign desativar = (desativar_in & na_ativo_out) & ga_habilitar_in;
assign desativar_aprovado = desativar_in & aprovado;
assign atualizar = (atualizar_in & na_ativo_out) & ga_habilitar_in;
assign nova_menor_distancia = na_distancia_out > distancia_in;
assign aprovado = (ca_criterio_geral_in >= na_distancia_out) & na_ativo_out;

always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		menor_vizinho_r <= {CUSTO_WIDTH{1'b0}};
	end
	else begin
		// Momento de ativação salvar o menor vizinho
		if (ativar) begin
			menor_vizinho_r <= menor_vizinho_in;
		end
	end
end

//*******************************************************
//Outputs
//*******************************************************
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		na_aprovado_out <= 1'b0;
	end
	else begin
		if (aprovado)
			na_aprovado_out <= 1'b1;
		else
			na_aprovado_out <= 1'b0;
	end
end

always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		na_endereco_out <= {ADDR_WIDTH{1'b1}};
	end
	else begin
		// Momento de ativação
		if (ativar) begin
			na_endereco_out <= endereco_in;
		end
	end
end

always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		na_distancia_out <= {DISTANCIA_WIDTH{1'b0}};
		na_anterior_out <= {CRITERIO_WIDTH{1'b1}};
	end
	else begin
		// Momento de ativação
		if (ativar) begin
			na_distancia_out <= distancia_in;
			na_anterior_out <= anterior_in;
		end
		// Já se enconstra ativado, apenas atualizando
		else if (atualizar & nova_menor_distancia) begin
			na_distancia_out <= distancia_in;
			na_anterior_out <= anterior_in;
		end
	end
end

always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		na_ativo_out <= {1'b0};
	end
	else begin
		if (ga_habilitar_in && atualizar_in) begin
			na_ativo_out <= 1'b1;
		end
		else if (desativar_aprovado) begin
			na_ativo_out <= 1'b0;
		end
	end
end

always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		na_criterio_out <= {CRITERIO_WIDTH{1'b1}};
	end
	else begin
		if (na_ativo_out)
			na_criterio_out <= menor_vizinho_r + na_distancia_out;
		else
			na_criterio_out <= {CRITERIO_WIDTH{1'b1}};
	end
end

endmodule