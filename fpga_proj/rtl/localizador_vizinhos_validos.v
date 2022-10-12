//==================================================================================================
//  Filename      : localizador_vizinhos_validos.v
//  Created On    : 2022-10-04 09:59:38
//  Last Modified : 2022-10-12 17:14:24
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
			ADDR_WIDTH = 8,
			MAX_VIZINHOS = 8,
			RELACOES_DATA_WIDTH = 8,
			NUM_NA = 4,
	        DISTANCIA_WIDTH = 5,
	        CUSTO_WIDTH = 4,
	        DATA_WIDTH = 4
		)
		(/*autoport*/
			input clk,
			input rst_n,
			input aa_ocupado_in,
			input [NUM_NA-1:0] aa_aprovado_in,
      		input [ADDR_WIDTH*NUM_NA-1:0] aa_endereco_in,
			input [DISTANCIA_WIDTH*NUM_NA-1:0] aa_distancia_in,
      		// input aa_tem_ativo_in,
      		// input aa_tem_aprovado_in,
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
			// Indicando que o processamento atual termninou
			output lvv_pronto_out
			
		);
//*******************************************************
//Internal
//*******************************************************
//Local Parameters
genvar i;
localparam COUNT_WIDTH = 10;
// endereco_w, custo_vw, menor_vizinho, aprovado, distancia_v
localparam FIFO_DATA_WIDTH = ADDR_WIDTH + CUSTO_WIDTH + ADDR_WIDTH + DISTANCIA_WIDTH;
localparam FIDO_ADDR_WIDTH = 5;
//Wires
wire [ADDR_WIDTH-1:0] aa_endereco_2d [0:NUM_NA-1];
wire [DISTANCIA_WIDTH-1:0] aa_distancia_2d [0:NUM_NA-1];
// sinais da fifo de saída
wire fifo_full;
wire fifo_almost_full;
wire fifo_empty;
wire fifo_almost_empty;
// wire ler_fifo;
wire [FIFO_DATA_WIDTH-1:0] fifo_data_out;
//Registers
reg [FIFO_DATA_WIDTH-1:0] fifo_data_in;
reg [COUNT_WIDTH-1:0] count_aprovados;
reg [RELACOES_DATA_WIDTH-1:0] gma_relacoes_rd_data_ap;
reg [RELACOES_DATA_WIDTH-1:0] gma_relacoes_rd_data_reg;
//*******************************************************
//General Purpose Signals
//*******************************************************

//*******************************************************
// Desempacotando leitura de relações de um no
//*******************************************************
localparam UMA_RELACAO_WIDTH = ADDR_WIDTH+CUSTO_WIDTH;
wire [UMA_RELACAO_WIDTH-1:0] relacoes_2d_ap [0:MAX_VIZINHOS-1];
wire [CUSTO_WIDTH-1:0] relacoes_2d_custo_ap [0:MAX_VIZINHOS-1];
wire [ADDR_WIDTH-1:0] relacoes_2d_addr_ap [0:MAX_VIZINHOS-1];

wire [UMA_RELACAO_WIDTH-1:0] relacoes_2d_in [0:MAX_VIZINHOS-1];
wire [CUSTO_WIDTH-1:0] relacoes_2d_custo_in [0:MAX_VIZINHOS-1];
wire [ADDR_WIDTH-1:0] relacoes_2d_addr_in [0:MAX_VIZINHOS-1];

wire [UMA_RELACAO_WIDTH-1:0] relacoes_2d_reg [0:MAX_VIZINHOS-1];
wire [CUSTO_WIDTH-1:0] relacoes_2d_custo_reg [0:MAX_VIZINHOS-1];
wire [ADDR_WIDTH-1:0] relacoes_2d_addr_reg [0:MAX_VIZINHOS-1];

generate
    for (i = 0; i < MAX_VIZINHOS; i = i + 1) begin:convert_dimension_relacao
		assign relacoes_2d_ap[i] = gma_relacoes_rd_data_ap[UMA_RELACAO_WIDTH*i+UMA_RELACAO_WIDTH-1:UMA_RELACAO_WIDTH*i];
		assign relacoes_2d_custo_ap[i] = relacoes_2d_ap[i][CUSTO_WIDTH-1:0];
		assign relacoes_2d_addr_ap[i] = relacoes_2d_ap[i][ADDR_WIDTH-1+CUSTO_WIDTH:CUSTO_WIDTH];

		assign relacoes_2d_in[i] = gma_relacoes_rd_data_in[UMA_RELACAO_WIDTH*i+UMA_RELACAO_WIDTH-1:UMA_RELACAO_WIDTH*i];
		assign relacoes_2d_custo_in[i] = relacoes_2d_in[i][CUSTO_WIDTH-1:0];
		assign relacoes_2d_addr_in[i] = relacoes_2d_in[i][ADDR_WIDTH-1+CUSTO_WIDTH:CUSTO_WIDTH];

		assign relacoes_2d_reg[i] = gma_relacoes_rd_data_reg[UMA_RELACAO_WIDTH*i+UMA_RELACAO_WIDTH-1:UMA_RELACAO_WIDTH*i];
		assign relacoes_2d_custo_reg[i] = relacoes_2d_reg[i][CUSTO_WIDTH-1:0];
		assign relacoes_2d_addr_reg[i] = relacoes_2d_reg[i][ADDR_WIDTH-1+CUSTO_WIDTH:CUSTO_WIDTH];
		
		// assign relacoes_2d_in[i] = gma_relacoes_rd_data_reg[UMA_RELACAO_WIDTH*i+UMA_RELACAO_WIDTH-1:UMA_RELACAO_WIDTH*i];
    end
endgenerate

//*******************************************************
// Estabelecendo os nós aprovados e desativando no AA
//*******************************************************



// assign  lvv_relacoes_rd_enable_out = lvv_estabelecidos_write_en_out;
// assign  lvv_relacoes_rd_addr_out = lvv_estabelecidos_write_addr_out;

always @(*) begin
	lvv_estabelecidos_write_en_out = 1'b0;
	lvv_estabelecidos_write_data_out = 1'b0;
	lvv_estabelecidos_write_addr_out = aa_endereco_2d[count_aprovados];	
	if (state == ST_ENCONTRAR_VIZINHOS) begin
		lvv_estabelecidos_write_en_out = 1'b1;
		lvv_estabelecidos_write_data_out = 1'b1;
	end
	if (state == ST_FINALIZAR) begin
		lvv_estabelecidos_read_en_out = 1'b1;
		lvv_estabelecidos_read_addr_out = fifo_data_out[ADDR_WIDTH+DISTANCIA_WIDTH+CUSTO_WIDTH+ADDR_WIDTH-1:ADDR_WIDTH+DISTANCIA_WIDTH+CUSTO_WIDTH];
	end
end

always @(*) begin
	lvv_relacoes_rd_enable_out = 1'b0;
	lvv_relacoes_rd_addr_out = aa_endereco_2d[count_aprovados];
	if (state == ST_ENCONTRAR_VIZINHOS) begin
		lvv_relacoes_rd_enable_out = 1'b1;
		// lvv_relacoes_rd_addr_out = aa_endereco_2d[count_aprovados];	
	end
	else if (state == ST_EXPANDIR_VIZINHOS) begin
		lvv_relacoes_rd_enable_out = 1'b1;
		lvv_relacoes_rd_addr_out = relacoes_2d_addr_ap[count_vizinho];	
	end
	else if (state == ST_ENCONTRAR_MENOR) begin
		lvv_relacoes_rd_enable_out = 1'b1;
		lvv_relacoes_rd_addr_out = relacoes_2d_addr_ap[count_vizinho];	
	end

	else if (state == ST_SALVAR_MENOR) begin
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
//registrando as relações de um nó aprovado
//*******************************************************
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		gma_relacoes_rd_data_ap <= {RELACOES_DATA_WIDTH{1'b0}};
		gma_relacoes_rd_data_reg <= {RELACOES_DATA_WIDTH{1'b0}};
	end
	else begin
		if (lvv_relacoes_rd_enable_out)
			gma_relacoes_rd_data_reg <= gma_relacoes_rd_data_in;
		if (state == ST_ENCONTRAR_VIZINHOS)
			gma_relacoes_rd_data_ap <= gma_relacoes_rd_data_in;
	end
end
//*******************************************************
// Contador de nós aprovados
//*******************************************************
always @(posedge clk or negedge rst_n) begin
   if (!rst_n) begin
      count_aprovados <= {COUNT_WIDTH{1'b0}};
   end
   else begin
      if (state == ST_IDLE) begin
         count_aprovados <= {COUNT_WIDTH{1'b0}};
      end
      else if (next_state == ST_ENCONTRAR_APROVADO)
         count_aprovados <= count_aprovados + 1'b1;
   end
end

localparam COUNT_VIZINHO_WIDTH = 3;
reg [COUNT_VIZINHO_WIDTH-1:0] count_vizinho;

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


reg [COUNT_VIZINHO_WIDTH-1:0] count_sub_vizinho;

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


reg [STATE_WIDTH-1:0] state, next_state;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state <= ST_IDLE;
    end
    else begin
        state <= next_state;
    end
end


wire salvar_menor;
wire no_aprovado;
wire vizinho_invalido;
wire vizinho_invalido_in;
wire [ADDR_WIDTH-1:0] endereco_vizinho_atual;
assign endereco_vizinho_atual = relacoes_2d_addr_ap[count_vizinho];
assign salvar_menor = state == ST_SALVAR_MENOR;
assign no_aprovado = aa_aprovado_in[count_aprovados] == 1'b1;
assign vizinho_invalido = endereco_vizinho_atual == {ADDR_WIDTH{1'b1}};
assign vizinho_invalido_in = relacoes_2d_addr_in[count_sub_vizinho] == {ADDR_WIDTH{1'b1}};
assign lvv_pronto_out = state == ST_IDLE;

localparam STATE_WIDTH = 3;
localparam ST_IDLE = 0,
		   ST_ENCONTRAR_APROVADO = 1,
		   ST_ENCONTRAR_VIZINHOS = 2,
		   ST_ANALISAR_VIZINHO = 3,
		   ST_ENCONTRAR_MENOR = 4,
		   ST_SALVAR_MENOR = 5,
		   ST_EXPANDIR_VIZINHOS = 6,
		   ST_FINALIZAR = 7;

always @(*) begin
    next_state = state;
    case (state)
        ST_IDLE:
            if (cme_expandir_in)
                next_state = ST_ENCONTRAR_APROVADO;
        // Identificando um nó aprovado a ser analizado
        ST_ENCONTRAR_APROVADO:
            if (no_aprovado)
                next_state = ST_ENCONTRAR_VIZINHOS;
            else if (count_aprovados == NUM_NA-1)
            	next_state = ST_FINALIZAR;
        // Encontrando os vizinhos de um nó aprovado
        ST_ENCONTRAR_VIZINHOS:
            next_state = ST_ANALISAR_VIZINHO;
        // Analisando cada um dos vizinhos de um nó aprovado, primeiramente identificando se o mesmo é válido
        ST_ANALISAR_VIZINHO:
        	if (vizinho_invalido)
            	next_state = ST_EXPANDIR_VIZINHOS;
            else if (gma_obstaculos_rd_data_in == 1'b1)
            	next_state = ST_EXPANDIR_VIZINHOS;
            else
            	next_state = ST_ENCONTRAR_MENOR;
        // Entre os vizinhos do vizinho, encontrando aquele que possui o menor custo
        ST_ENCONTRAR_MENOR:
        	if (relacoes_2d_addr_in[count_sub_vizinho-1] != endereco_vizinho_atual) // Para não adicionar o nó aprovado
	        	if (!vizinho_invalido_in ) 
	            	if (gma_obstaculos_rd_data_in == 1'b0)
	            		next_state = ST_SALVAR_MENOR;
        ST_SALVAR_MENOR:
        	next_state = ST_EXPANDIR_VIZINHOS;
        ST_EXPANDIR_VIZINHOS:
        	if (count_vizinho != MAX_VIZINHOS-1)
        		next_state = ST_ANALISAR_VIZINHO;
        	else
        		next_state = ST_ENCONTRAR_APROVADO;
        ST_FINALIZAR:
        	if (fifo_empty && !aa_ocupado_in)
        		next_state = ST_IDLE;
    endcase
end
//*******************************************************
// Convertendo entradas para 2d
//*******************************************************

generate
    for (i = 0; i < NUM_NA; i = i + 1) begin:convert_dimension_in
		assign aa_endereco_2d[i] = aa_endereco_in[ADDR_WIDTH*i+ADDR_WIDTH-1:ADDR_WIDTH*i];
		assign aa_distancia_2d[i] = aa_distancia_in[DISTANCIA_WIDTH*i+DISTANCIA_WIDTH-1:DISTANCIA_WIDTH*i];
    end
endgenerate

//*******************************************************
//Salvando menor vizinho
//*******************************************************
reg [ADDR_WIDTH-1:0] endereco_w;
reg [CUSTO_WIDTH-1:0]custo_vw;
reg [CUSTO_WIDTH-1:0] menor_vizinho;
reg [ADDR_WIDTH-1:0] aprovado;
reg [DISTANCIA_WIDTH-1:0] distancia_v;
reg [DISTANCIA_WIDTH-1:0] nova_distancia;
always @(*) begin
	// endereco_w, custo_vw, menor_vizinho, aprovado, distancia_v
	endereco_w = salvar_menor ? relacoes_2d_addr_ap[count_vizinho] : 0;
	custo_vw = salvar_menor ? relacoes_2d_custo_ap[count_vizinho] : 0;
	menor_vizinho = salvar_menor ? relacoes_2d_custo_in[count_sub_vizinho-1] : 0;
	aprovado = salvar_menor ? aa_endereco_2d[count_aprovados] : 0;
	distancia_v = salvar_menor ? aa_distancia_2d[count_aprovados] : 0;
	nova_distancia = distancia_v + custo_vw;
	fifo_data_in = salvar_menor ? {endereco_w, menor_vizinho, aprovado, nova_distancia} : {FIFO_DATA_WIDTH{1'b10}};
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
		if (state == ST_ENCONTRAR_VIZINHOS) begin
			lvv_desativar_out <= lvv_estabelecidos_write_en_out;
			lvv_desativar_addr_out <= lvv_estabelecidos_write_addr_out;
			lvv_endereco_out <= lvv_estabelecidos_write_addr_out;
		end
		else if (!fifo_empty && lvv_atualizar_out != 1'b1 && !aa_ocupado_in && state == ST_FINALIZAR && !ge_estabelecidos_read_data_in) begin
			lvv_atualizar_out <= 1'b1;
			lvv_endereco_out <= fifo_data_out[ADDR_WIDTH+DISTANCIA_WIDTH+CUSTO_WIDTH+ADDR_WIDTH-1:ADDR_WIDTH+DISTANCIA_WIDTH+CUSTO_WIDTH];
			lvv_menor_vizinho_out <= fifo_data_out[ADDR_WIDTH+DISTANCIA_WIDTH+CUSTO_WIDTH-1:ADDR_WIDTH+DISTANCIA_WIDTH];
			lvv_anterior_out <= fifo_data_out[ADDR_WIDTH+DISTANCIA_WIDTH-1:DISTANCIA_WIDTH];;
			lvv_distancia_out <= fifo_data_out[DISTANCIA_WIDTH-1:0];
		end
		else begin
			lvv_atualizar_out <= 1'b0;
			lvv_desativar_out <= 1'b0;
		end
	end
end
//*******************************************************
//Instantiations
//*******************************************************

syn_fifo 
#(
    .DATA_WIDTH(FIFO_DATA_WIDTH),
    .ADDR_WIDTH(FIDO_ADDR_WIDTH)
  )
fifo_saida
  (
    .clk(clk),
    .rst_n(rst_n),
    .rd_en(lvv_atualizar_out),
    .wr_en(salvar_menor),
    .data_in(fifo_data_in),
    .full(fifo_full),
    .almost_full(fifo_almost_full),
    .empty(fifo_empty),
    .almost_empty(fifo_almost_empty),
    .data_out(fifo_data_out)
);

endmodule