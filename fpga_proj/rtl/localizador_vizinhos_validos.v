//==================================================================================================
//  Filename      : localizador_vizinhos_validos.v
//  Created On    : 2022-10-04 09:59:38
//  Last Modified : 2022-10-25 15:11:27
//  Revision      : 
//  Author        : Linton Esteves
//  Company       : UFBA
//  Email         : lintonthiago@gmail.com
//
//  Description   : Para cada nó aprovado é necessário encontrar todos os seus vizinhos, identificando 
//  aqueles que não são obstáculos e que não estão estabelecidos. Para cada um dos vizinhos encontrados
//  é necessário identificar o vizinho do vizinho com um menor custo. Dessa forma, para cada aprovado
//  são realizadas as seguintes leituras, considerando MAX_VIZINHOS a quantidade de vizinhos máxima de um nó:
//  1) 1x Memória de relações - identificação das relações do nó
//  2) MAX_VIZINHOSx Memória de obstáculos - remoção das relações que são obstáculos
//  3) MAX_VIZINHOSx Memória de estabelecidos - remoção das relações que são estabelecidos
//  4) MAX_VIZINHOSx Memória de relações - identificação das relações do vizinho para identificar o menor vizinho
//  5) MAX_VIZINHOSxMAX_VIZINHOSx Memória de obstáculos - identificação dos obstaculos do menor vizinho
//==================================================================================================
module localizador_vizinhos_validos
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
			// Lendo relações de um nó
			output reg lvv_relacoes_rd_enable_out,
			output reg [ADDR_WIDTH-1:0] lvv_relacoes_rd_addr_out,
			input [RELACOES_DATA_WIDTH-1:0] gma_relacoes_rd_data_in,
			// Lendo obstáculos
			output reg lvv_obstaculos_rd_enable_out,
			output reg [ADDR_WIDTH-1:0] lvv_obstaculos_rd_addr_out,
			input gma_obstaculos_rd_data_in,
			// Atualizando os estabelecidos
			output reg lvv_estabelecidos_write_en_out,
			output reg lvv_estabelecidos_write_data_out,
			output reg [ADDR_WIDTH-1:0] lvv_estabelecidos_write_addr_out,
			//lendo estabelecidos
			output reg lvv_estabelecidos_read_en_out,
			output reg [ADDR_WIDTH-1:0] lvv_estabelecidos_read_addr_out,
			input ge_estabelecidos_read_data_in,
			// Atualizando anterior
			output reg [ADDR_WIDTH-1:0] lvv_anterior_data_out,
			// Indicando que o processamento atual termninou
			output lvv_pronto_out
			
		);
//*******************************************************
//Internal
//*******************************************************
//Local Parameters
genvar i;
localparam COUNT_WIDTH = 10;
localparam COUNT_VIZINHO_WIDTH = 3;
localparam STATE_WIDTH = 4;
localparam ST_IDLE = 4'd0,
		   ST_ENCONTRAR_APROVADO = 4'd1,
		   ST_ENCONTRAR_VIZINHOS = 4'd2,
		   ST_ANALISAR_VIZINHO = 4'd3,
		   ST_ENCONTRAR_MENOR = 4'd4,
		   ST_SALVAR_MENOR = 4'd5,
		   ST_EXPANDIR_VIZINHOS = 4'd6,
		   ST_FINALIZAR = 4'd7,
		   ST_ESTABILIZAR = 4'd8;
//Wires
wire [ADDR_WIDTH-1:0] aa_endereco_2d [0:NUM_NA-1];
wire [ADDR_WIDTH-1:0] aa_anterior_data_2d [0:NUM_NA-1];
wire [DISTANCIA_WIDTH-1:0] aa_distancia_2d [0:NUM_NA-1];
wire no_aprovado;
wire vizinho_invalido;
wire vizinho_invalido_in;
wire [ADDR_WIDTH-1:0] endereco_vizinho_atual;
wire nao_vizinho_atual;
wire [UMA_RELACAO_WIDTH-1:0] relacoes_2d_ap [0:MAX_VIZINHOS-1];
wire [CUSTO_WIDTH-1:0] relacoes_2d_custo_ap [0:MAX_VIZINHOS-1];
wire [ADDR_WIDTH-1:0] relacoes_2d_addr_ap [0:MAX_VIZINHOS-1];
wire [UMA_RELACAO_WIDTH-1:0] relacoes_2d_in [0:MAX_VIZINHOS-1];
wire [CUSTO_WIDTH-1:0] relacoes_2d_custo_in [0:MAX_VIZINHOS-1];
wire [ADDR_WIDTH-1:0] relacoes_2d_addr_in [0:MAX_VIZINHOS-1];
wire tem_aprovado;
//Registers
reg lvv_pronto;
reg [RELACOES_DATA_WIDTH-1:0] gma_relacoes_rd_data_ap;
reg [COUNT_VIZINHO_WIDTH-1:0] count_vizinho;
reg [STATE_WIDTH-1:0] state, next_state;
reg [COUNT_VIZINHO_WIDTH-1:0] count_sub_vizinho;
reg [ADDR_WIDTH-1:0] endereco_w;
reg [CUSTO_WIDTH-1:0]custo_vw;
reg [CUSTO_WIDTH-1:0] menor_vizinho;
reg [ADDR_WIDTH-1:0] aprovado;
reg [DISTANCIA_WIDTH-1:0] distancia_v;
reg [DISTANCIA_WIDTH-1:0] nova_distancia;
reg [NUM_NA-1:0] aprovados_reg;
reg [ADDR_WIDTH-1:0] proximo_aprovado;

//*******************************************************
//General Purpose Signals
//*******************************************************
assign endereco_vizinho_atual = relacoes_2d_addr_ap[count_vizinho];
assign no_aprovado = aa_aprovado_in[proximo_aprovado] == 1'b1;
assign no_aprovado_prox = aa_aprovado_in[proximo_aprovado] == 1'b1;
assign vizinho_invalido = endereco_vizinho_atual == {ADDR_WIDTH{1'b1}};
assign vizinho_invalido_in = relacoes_2d_addr_in[count_sub_vizinho] == {ADDR_WIDTH{1'b1}};
assign lvv_pronto_out = state == ST_FINALIZAR;
assign tem_aprovado = aprovados_reg != 0;
//*******************************************************
// Desempacotando leitura de relações de um no
//*******************************************************
generate
    for (i = 0; i < MAX_VIZINHOS; i = i + 1) begin:convert_dimension_relacao
		assign relacoes_2d_ap[MAX_VIZINHOS-1-i] = gma_relacoes_rd_data_ap[UMA_RELACAO_WIDTH*i+UMA_RELACAO_WIDTH-1:UMA_RELACAO_WIDTH*i];
		assign relacoes_2d_custo_ap[i] = relacoes_2d_ap[i][CUSTO_WIDTH-1:0];
		assign relacoes_2d_addr_ap[i] = relacoes_2d_ap[i][ADDR_WIDTH-1+CUSTO_WIDTH:CUSTO_WIDTH];

		assign relacoes_2d_in[MAX_VIZINHOS-1-i] = gma_relacoes_rd_data_in[UMA_RELACAO_WIDTH*i+UMA_RELACAO_WIDTH-1:UMA_RELACAO_WIDTH*i];
		assign relacoes_2d_custo_in[i] = relacoes_2d_in[i][CUSTO_WIDTH-1:0];
		assign relacoes_2d_addr_in[i] = relacoes_2d_in[i][ADDR_WIDTH-1+CUSTO_WIDTH:CUSTO_WIDTH];
    end
endgenerate
//*******************************************************
//analisando entrada
//*******************************************************
integer w;
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		proximo_aprovado <= 0;
	end
	else begin
		proximo_aprovado <= 0;
		for (w = 0; w < NUM_NA; w = w +1) begin
			if (aprovados_reg[w]==1)
				proximo_aprovado <= w;
		end
	end
end


always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		aprovados_reg <= 0;
	end
	else begin
		if (state==ST_IDLE || (state == ST_ESTABILIZAR && !tem_aprovado))
			aprovados_reg <= aa_aprovado_in;
		
		if (lvv_estabelecidos_write_en_out || (state == ST_EXPANDIR_VIZINHOS && next_state ==ST_ENCONTRAR_APROVADO))
			aprovados_reg[proximo_aprovado] <= 1'b0;
	end
end

//*******************************************************
//registrando as relações de um nó aprovado
//*******************************************************
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		gma_relacoes_rd_data_ap <= {RELACOES_DATA_WIDTH{1'b0}};
	end
	else begin
		if (state == ST_ENCONTRAR_VIZINHOS)
			gma_relacoes_rd_data_ap <= gma_relacoes_rd_data_in;
	end
end

//*******************************************************
// Convertendo entradas para 2d
//*******************************************************
generate
    for (i = 0; i < NUM_NA; i = i + 1) begin:convert_dimension_in
		assign aa_endereco_2d[i] = aa_endereco_in[ADDR_WIDTH*i+ADDR_WIDTH-1:ADDR_WIDTH*i];
		assign aa_anterior_data_2d[i] = aa_anterior_data_in[ADDR_WIDTH*i+ADDR_WIDTH-1:ADDR_WIDTH*i];
		assign aa_distancia_2d[i] = aa_distancia_in[DISTANCIA_WIDTH*i+DISTANCIA_WIDTH-1:DISTANCIA_WIDTH*i];
    end
endgenerate

//*******************************************************
// Estabelecendo os nós aprovados e desativando no AA
//*******************************************************
always @(*) begin
	lvv_estabelecidos_write_en_out = 1'b0;
	lvv_estabelecidos_read_en_out = 1'b0;
	lvv_estabelecidos_write_data_out = 1'b0;
	lvv_estabelecidos_read_addr_out = endereco_w;
	lvv_estabelecidos_write_addr_out = aa_endereco_2d[proximo_aprovado];
	if (state == ST_ESTABILIZAR && !lvv_desativar_out && !aa_ocupado_in) begin
		lvv_estabelecidos_write_en_out = 1'b1;
		lvv_estabelecidos_write_data_out = 1'b1;
	end
	if (state == ST_SALVAR_MENOR) begin
		lvv_estabelecidos_read_en_out = 1'b1;
	end
end

always @(*) begin
	lvv_anterior_data_out = aa_anterior_data_2d[proximo_aprovado];
end

always @(*) begin
	lvv_relacoes_rd_enable_out = 1'b0;
	lvv_relacoes_rd_addr_out = aa_endereco_2d[proximo_aprovado];
	if (state == ST_ENCONTRAR_VIZINHOS) begin
		lvv_relacoes_rd_enable_out = 1'b1;
	end
	else if (state == ST_EXPANDIR_VIZINHOS || state == ST_ENCONTRAR_MENOR || state == ST_SALVAR_MENOR) begin
		lvv_relacoes_rd_enable_out = 1'b1;
		lvv_relacoes_rd_addr_out = relacoes_2d_addr_ap[count_vizinho];	
	end
end

always @(*) begin
	lvv_obstaculos_rd_enable_out = 0;
	lvv_obstaculos_rd_addr_out = relacoes_2d_addr_ap[count_vizinho];
	if (state == ST_EXPANDIR_VIZINHOS) begin
		lvv_obstaculos_rd_enable_out = 1'b1;
		lvv_obstaculos_rd_addr_out = relacoes_2d_addr_ap[count_vizinho];	
	end
	else if (state == ST_ENCONTRAR_MENOR || state == ST_SALVAR_MENOR) begin
		lvv_obstaculos_rd_enable_out = 1'b1;
		lvv_obstaculos_rd_addr_out = relacoes_2d_addr_in[count_sub_vizinho];	
	end
end

//*******************************************************
// Contadores
//*******************************************************
// Contador dos vizinhos de um nó
always @(posedge clk or negedge rst_n) begin
   if (!rst_n) begin
      count_vizinho <= {COUNT_VIZINHO_WIDTH{1'b0}};
   end
   else begin
      if (state == ST_EXPANDIR_VIZINHOS)
         count_vizinho <= count_vizinho + 1'b1;
      else if (state == ST_ENCONTRAR_VIZINHOS) begin
         count_vizinho <= {COUNT_VIZINHO_WIDTH{1'b0}};
      end
   end
end

//Contador dos subvizinhos
always @(posedge clk or negedge rst_n) begin
   if (!rst_n) begin
      count_sub_vizinho <= {COUNT_VIZINHO_WIDTH{1'b0}};
   end
   else begin
      if (state == ST_ENCONTRAR_MENOR)
         count_sub_vizinho <= count_sub_vizinho + 1'b1;
      else if (state == ST_ANALISAR_VIZINHO) begin
         count_sub_vizinho <= {COUNT_VIZINHO_WIDTH{1'b0}};
      end
   end
end

//*******************************************************
//FSM
//*******************************************************
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state <= ST_IDLE;
    end
    else begin
        state <= next_state;
    end
end

always @(*) begin
    next_state = state;
    case (state)
        ST_IDLE:
            if (cme_expandir_in && !lvv_pronto && !lvv_pronto_out)
                next_state = ST_ESTABILIZAR;
        // Esdtabilizandos os nós aprovados
        ST_ESTABILIZAR:
	        if (!tem_aprovado)
	            next_state = ST_ENCONTRAR_APROVADO;
	    //Identificando os aprovados
        ST_ENCONTRAR_APROVADO:
            if (tem_aprovado)
                next_state = ST_ENCONTRAR_VIZINHOS;
            else
            	next_state = ST_FINALIZAR;
        // Encontrando os vizinhos de um nó aprovado
        ST_ENCONTRAR_VIZINHOS:
            next_state = ST_ANALISAR_VIZINHO;
        // Analisando cada um dos vizinhos de um nó aprovado, primeiramente identificando se o mesmo é válido
        ST_ANALISAR_VIZINHO:
        	if (vizinho_invalido || gma_obstaculos_rd_data_in == 1'b1)
            	next_state = ST_EXPANDIR_VIZINHOS;
            else
            	next_state = ST_ENCONTRAR_MENOR;
        // Entre os vizinhos do vizinho, encontrando aquele que possui o menor custo
        ST_ENCONTRAR_MENOR:
        	if (nao_vizinho_atual && !vizinho_invalido_in && gma_obstaculos_rd_data_in == 1'b0) // Para não adicionar o nó aprovado
        		next_state = ST_SALVAR_MENOR;
		    else if (count_sub_vizinho == MAX_VIZINHOS-1)
		    	next_state = ST_EXPANDIR_VIZINHOS;
        ST_SALVAR_MENOR:
        	next_state = ST_EXPANDIR_VIZINHOS;
        ST_EXPANDIR_VIZINHOS:
        	if (count_vizinho != MAX_VIZINHOS-1)
        		next_state = ST_ANALISAR_VIZINHO;
        	else
        		if (!tem_aprovado)
        			next_state = ST_FINALIZAR;
        		else
        			next_state = ST_ENCONTRAR_APROVADO;
        ST_FINALIZAR:
        		next_state = ST_IDLE;
    endcase
end

assign nao_vizinho_atual = relacoes_2d_addr_in[count_sub_vizinho] != endereco_vizinho_atual;

//*******************************************************
//Salvando menor vizinho
//*******************************************************
always @(*) begin
	// endereco_w, custo_vw, menor_vizinho, aprovado, distancia_v
	endereco_w = relacoes_2d_addr_ap[count_vizinho];
	custo_vw = relacoes_2d_custo_ap[count_vizinho];
	
	menor_vizinho = relacoes_2d_custo_in[count_sub_vizinho-1];
	
	aprovado = aa_endereco_2d[proximo_aprovado];
	distancia_v = aa_distancia_2d[proximo_aprovado];
	
	nova_distancia = distancia_v + custo_vw;
end

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
	end
	else begin
		lvv_desativar_out <= 1'b0;
		lvv_atualizar_out <= 1'b0;
		lvv_menor_vizinho_out <= menor_vizinho;
		lvv_desativar_addr_out <= lvv_estabelecidos_write_addr_out;
		lvv_anterior_out <= aprovado;
		if (state == ST_ESTABILIZAR && !lvv_desativar_out && !aa_ocupado_in) begin
			lvv_desativar_out <= lvv_estabelecidos_write_en_out;
			lvv_endereco_out <= lvv_estabelecidos_write_addr_out;
		end
		else if (state == ST_SALVAR_MENOR) begin
			lvv_endereco_out <= endereco_w;
			lvv_distancia_out <= distancia_v + custo_vw;
			
			if (lvv_atualizar_out != 1'b1 && !aa_ocupado_in && !ge_estabelecidos_read_data_in)
				lvv_atualizar_out <= 1'b1;
		end
	end
end

always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		lvv_pronto <= 1'b0;
	end
	else begin
		lvv_pronto <= lvv_pronto_out;
	end
end

endmodule