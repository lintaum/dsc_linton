//==================================================================================================
//  Filename      : no_ativo.v
//  Created On    : 2022-08-30 07:30:13
//  Last Modified : 2022-08-30 10:20:24
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
            parameter ADR_WIDTH = 5,
            parameter DISTANCIA_WIDTH = 5,
            parameter CRITERIO_WIDTH = 5,
            parameter CUSTO_WIDTH = 4
		)
		(/*autoport*/
			input clk,
			input rst_n,
			input [CUSTO_WIDTH-1:0] menor_vizinho_in,
			input [DISTANCIA_WIDTH-1:0] distancia_in,
			input [CRITERIO_WIDTH-1:0] ca_criterio_geral_in,
			input [ADR_WIDTH-1:0] endereco_in,
			input [ADR_WIDTH-1:0] anterior_in,
			input atualizar_in,
			input desativar_in,
			input ga_habilitar_in,
			output reg [CRITERIO_WIDTH-1:0] na_criterio_out,
			output reg [DISTANCIA_WIDTH-1:0] na_distancia_out,
			output reg na_atualizar_anterior_out,
			output reg [ADR_WIDTH-1:0] na_anterior_out,
			output reg na_aprovado_out,
			output reg [ADR_WIDTH-1:0] na_endereco_out,
			output reg na_ativo_out

		);
//*******************************************************
//Internal
//*******************************************************
//Local Parameters

//Wires
wire ativar, atualizar, menor_distancia, aprovado;
//Registers
reg [CUSTO_WIDTH-1:0] menor_vizinho_r;
//General Purpose Signals
//*******************************************************
assign ativar = atualizar_in & !na_ativo_out;
assign desativar = desativar_in & na_ativo_out;
assign atualizar = atualizar_in & na_ativo_out;
assign menor_distancia = na_distancia_out > distancia_in;
assign aprovado = !desativar &(ca_criterio_geral_in >= na_distancia_out) & na_ativo_out;


always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		menor_vizinho_r <= {CUSTO_WIDTH{1'b0}};
	end
	else begin
		// Momento de ativação
		if (ga_habilitar_in & ativar) begin
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
		na_endereco_out <= {ADR_WIDTH{1'b0}};
	end
	else begin
		// Momento de ativação
		if (ga_habilitar_in & ativar) begin
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
		if (ga_habilitar_in) begin
			// Momento de ativação
			if (ativar) begin
				na_distancia_out <= distancia_in;
				na_anterior_out <= anterior_in;
			end
			// Já se enconstra ativado, apenas atualizando
			else if (atualizar & menor_distancia) begin
				na_distancia_out <= distancia_in;
				na_anterior_out <= anterior_in;
			end
		end
	end
end

always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		na_ativo_out <= {1'b0};
	end
	else begin
		if (ga_habilitar_in) begin
			if (atualizar_in)
				na_ativo_out <= 1'b1;
			else if (!atualizar_in & desativar_in)
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

always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		na_atualizar_anterior_out <= 1'b0;
	end
	else begin
		if (ga_habilitar_in & desativar)
			na_atualizar_anterior_out<= 1'b1;
		else
			na_atualizar_anterior_out<= 1'b0;
	end
end

endmodule