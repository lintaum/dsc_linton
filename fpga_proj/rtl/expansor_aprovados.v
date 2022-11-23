//==================================================================================================
//  Filename      : expansor_aprovados.v
//  Created On    : 2022-11-23 08:07:40
//  Last Modified : 2022-11-23 15:01:19
//  Revision      : 
//  Author        : Linton Esteves
//  Company       : UFBA
//  Email         : lintonthiago@gmail.com
//
//  Description   : 
//
//
//==================================================================================================
module expansor_aprovados
        #(  
            parameter ADDR_WIDTH = 10,
            parameter DISTANCIA_WIDTH = 6,
            parameter MAX_VIZINHOS = 8,
            parameter NUM_READ_PORTS = 8,
            parameter CUSTO_WIDTH = 4,
            parameter UMA_RELACAO_WIDTH = ADDR_WIDTH+CUSTO_WIDTH,
            parameter RELACOES_DATA_WIDTH = MAX_VIZINHOS*(UMA_RELACAO_WIDTH)
        )
        (/*autoport*/
            input clk,
            input rst_n,
            // Informações do aprovado
            input lvv_escrever_aprovado_in,
            input [RELACOES_DATA_WIDTH-1:0] lvv_relacoes_aprovado_in,
            input [ADDR_WIDTH-1:0] lvv_aprovado_addr_in,
            input [DISTANCIA_WIDTH-1:0] lvv_aprovado_distancia_in,
            // Lendo relações de um nó
            input lvv_relacoes_ready_in,
            input [RELACOES_DATA_WIDTH*NUM_READ_PORTS-1:0] gma_relacoes_rd_data_in,
            output reg ea_relacoes_rd_enable_out,
            output reg [ADDR_WIDTH*NUM_READ_PORTS-1:0] ea_relacoes_rd_addr_out,
            // Lendo obstáculos
            input lvv_obstaculos_ready_in,
            input [NUM_READ_PORTS-1:0] gma_obstaculos_rd_data_in,
            output reg ea_obstaculos_rd_enable_out,
            output reg [ADDR_WIDTH*NUM_READ_PORTS-1:0] ea_obstaculos_rd_addr_out,
            //lendo estabelecidos
            input lvv_estabelecido_ready_in,
            input [NUM_READ_PORTS-1:0] ge_estabelecidos_rd_data_in,
            output reg ea_estabelecidos_rd_en_out,
            output reg [ADDR_WIDTH*NUM_READ_PORTS-1:0] ea_estabelecidos_rd_addr_out,
            // Enviando nó salvo
            output reg ea_pronto_out,
            output reg ea_ocupado_out,
            output reg ea_atualizar_out,
            output reg [ADDR_WIDTH-1:0] ea_endereco_out,
            output reg [CUSTO_WIDTH-1:0] ea_menor_vizinho_out,
            output reg [DISTANCIA_WIDTH-1:0] ea_distancia_out,
            output [ADDR_WIDTH-1:0] ea_anterior_out,
        );
//*******************************************************
//Internal
//*******************************************************
//Local Parameters
genvar i, j;
integer w;
localparam STATE_WIDTH = 4;
localparam ST_IDLE = 4'd0,
           ST_LER_OBSTACULO = 4'd1,
           ST_LER_ESTABELECIDO = 4'd2,
           ST_SALVAR_STATUS = 4'd3,
           ST_LER_RELACOES = 4'd4,
           ST_IDENTIFICAR_SUBVIZINHOS = 4'd5,
           ST_LER_OBSTACULO_SUBVIZINHO = 4'd6,
           ST_SALVAR_MENOR = 4'd7;
localparam COUNT_DISTANCIA_WIDTH = 4;
//Wires
wire [RELACOES_DATA_WIDTH-1:0] relacoes_2d [0:NUM_READ_PORTS-1];
wire [UMA_RELACAO_WIDTH-1:0] relacoes_4d [0:MAX_VIZINHOS-1];
wire [CUSTO_WIDTH-1:0] relacoes_4d_custo [0:MAX_VIZINHOS-1];
wire [ADDR_WIDTH-1:0] relacoes_4d_addr [0:MAX_VIZINHOS-1];
wire salvou_todos, todos_analisados;
wire [ADDR_WIDTH-1] estabelecidos_rd_addr_2d [0:NUM_READ_PORTS-1];
wire [ADDR_WIDTH-1] obstaculos_rd_addr_2d [0:NUM_READ_PORTS-1];
wire [ADDR_WIDTH-1] relacoes_rd_addr_2d [0:NUM_READ_PORTS-1];
//Registers
reg [STATE_WIDTH-1:0] state, next_state;
reg [ADDR_WIDTH-1:0] endereco_aprovado;
reg [MAX_VIZINHOS-1:0] vizinho_salvo;
reg [MAX_VIZINHOS-1:0] vizinho_invalido;
reg [RELACOES_DATA_WIDTH*NUM_READ_PORTS-1:0] gma_relacoes_rd_data_reg;
reg [COUNT_DISTANCIA_WIDTH-1:0] count_distancia;
reg [DISTANCIA_WIDTH-1:0] distancias_reg [MAX_VIZINHOS-1:0]
reg [CUSTO_WIDTH-1:0] menor_vizinho_reg [MAX_VIZINHOS-1:0]
//*******************************************************
//Convertendo dimensões
//*******************************************************
generate
    for (i = 0; i < NUM_READ_PORTS; i = i + 1) begin:convert_1d_out
        assign ea_estabelecidos_rd_addr_out[ADDR_WIDTH*i+ADDR_WIDTH-1:ADDR_WIDTH*i] = estabelecidos_rd_addr_2d[i];
        assign ea_obstaculos_rd_addr_out[ADDR_WIDTH*i+ADDR_WIDTH-1:ADDR_WIDTH*i] = obstaculos_rd_addr_2d[i];
        assign ea_relacoes_rd_addr_out[ADDR_WIDTH*i+ADDR_WIDTH-1:ADDR_WIDTH*i] = relacoes_rd_addr_2d[i];
    end
endgenerate

generate
    for (i = 0; i < MAX_VIZINHOS; i = i + 1) begin:convert_2d_in
        assign relacoes_aprovado[MAX_VIZINHOS-1-i] = lvv_relacoes_aprovado_in[UMA_RELACAO_WIDTH*i+UMA_RELACAO_WIDTH-1:UMA_RELACAO_WIDTH*i];
        assign relacoes_aprovado_custo[i] = relacoes_aprovado[i][CUSTO_WIDTH-1:0];
        assign relacoes_aprovado_addr[i] = relacoes_aprovado[i][ADDR_WIDTH-1+CUSTO_WIDTH:CUSTO_WIDTH];
    end
endgenerate

generate
    for (i = 0; i < NUM_READ_PORTS; i = i + 1) begin:convert_1d_in
        assign relacoes_2d[NUM_READ_PORTS-1-i] = gma_relacoes_rd_data_reg[RELACOES_DATA_WIDTH*i+RELACOES_DATA_WIDTH-1:RELACOES_DATA_WIDTH*i];
    end
endgenerate

// Todo: testar isso aqui  
generate
    for (i = 0; i < NUM_READ_PORTS; i = i + 1) begin:convert_2d_in
        for (j = 0; j < MAX_VIZINHOS; j = j + 1) begin:convert_2d_4d_in
            assign relacoes_4d[j][MAX_VIZINHOS-1-i] = relacoes_2d[i][UMA_RELACAO_WIDTH*i+UMA_RELACAO_WIDTH-1:UMA_RELACAO_WIDTH*i];
            assign relacoes_4d_custo[j][i] = relacoes_4d[i][CUSTO_WIDTH-1:0];
            assign relacoes_4d_addr[j][i] = relacoes_4d[i][ADDR_WIDTH-1+CUSTO_WIDTH:CUSTO_WIDTH];
        end
    end
endgenerate

//*******************************************************
//Sinais de controle
//*******************************************************
assign salvou_todos = &(vizinho_salvo | vizinho_invalido);

//*******************************************************
//General Purpose Signals
//*******************************************************
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        endereco_aprovado <= {ADDR_WIDTH{1'b0}};
    end
    else begin
        if (lvv_escrever_aprovado_in)
            endereco_aprovado <= lvv_aprovado_addr_in;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        gma_relacoes_rd_data_reg <= {{1'b0}};
    end
    else begin
        if (lvv_relacoes_ready_in)
            gma_relacoes_rd_data_reg <= gma_relacoes_rd_data_in;
    end
end

//*******************************************************
//Salvando as novas distancias
//*******************************************************
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (w = 0; w < MAX_VIZINHOS; w = w +1) begin
            distancias_reg[w] <= {DISTANCIA_WIDTH{1'b1}};
        end
    end
    else begin
        if (state != IDLE) begin
            distancias_reg[count_distancia] <= lvv_aprovado_distancia_in + relacoes_aprovado_custo[count_distancia];
        end
        else begin
            for (w = 0; w < MAX_VIZINHOS; w = w +1) begin
                distancias_reg[w] <= {DISTANCIA_WIDTH{1'b1}};
            end
        end
    end
end

always @(posedge clk or negedge rst_n) begin
   if (!rst_n) begin
      count_distancia <= {COUNT_DISTANCIA_WIDTH{1'b0}};
   end
   else begin
      if (state != IDLE)
         count_distancia <= count_distancia + 1'b1;
      else begin
         count_distancia <= {COUNT_DISTANCIA_WIDTH{1'b0}};
      end
   end
end

//*******************************************************
//salvando os novos custos
//*******************************************************
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (w = 0; w < MAX_VIZINHOS; w = w +1) begin
            menor_vizinho_reg[w] <= {CUSTO_WIDTH{1'b1}};
        end
    end
    else begin
        if (state == ST_LER_OBSTACULO_SUBVIZINHO && lvv_obstaculos_ready_in == 1'b1) begin
            for (w = 0; w < NUM_READ_PORTS; w = w + 1) begin
                if (vizinho_salvo[w] == 1'b0 && gma_obstaculos_rd_data_in[w] == 1'b0)
                    menor_vizinho_reg[w] <= relacoes_4d_custo[count_subvizinho][w];
            end
        end
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        vizinho_salvo <= {NUM_READ_PORTS{1'b0}};
    end
    else begin
        if (state == IDLE) begin
            vizinho_salvo <= {NUM_READ_PORTS{1'b0}};
        end
        if (state == ST_LER_OBSTACULO_SUBVIZINHO && lvv_obstaculos_ready_in == 1'b1) begin
            for (w = 0; w < NUM_READ_PORTS; w = w + 1) begin
                vizinho_salvo[w] <= 1'b1;
            end
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
            if (lvv_escrever_aprovado_in)
                next_state = ST_LER_OBSTACULO;
        ST_LER_OBSTACULO:
            if (lvv_obstaculos_ready_in)
                next_state = ST_LER_ESTABELECIDO;
        ST_LER_ESTABELECIDO:
            if (lvv_estabelecido_ready_in)
                next_state = ST_SALVAR_STATUS;
        ST_SALVAR_STATUS:
                next_state = ST_LER_RELACOES;
        ST_LER_RELACOES:
            if (lvv_relacoes_ready_in)
                next_state = ST_IDENTIFICAR_SUBVIZINHOS;
        ST_IDENTIFICAR_SUBVIZINHOS:
                next_state = ST_LER_OBSTACULO_SUBVIZINHO;
        ST_LER_OBSTACULO_SUBVIZINHO:
            if (lvv_obstaculos_ready_in)
                next_state = ST_SALVAR_MENOR;
        ST_SALVAR_MENOR:
            if (salvou_todos || todos_analisados)
                next_state = ST_IDLE;
            else
                next_state = ST_SALVAR_MENOR;
    endcase
end

//*******************************************************
//Controle de vizinhos válidos
//*******************************************************
// Identifica os vizinhos do nó ativo que não são válidos
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        vizinho_invalido <= {NUM_READ_PORTS{1'b0}};
    end
    else begin
        if (state == IDLE) begin
            vizinho_invalido <= {NUM_READ_PORTS{1'b0}};
        end
        // Vizinho que é obstáculo
        else if (state == ST_LER_OBSTACULO && lvv_obstaculos_ready_in) begin
            for (w = 0; w < NUM_READ_PORTS; w = w +1) begin
                if (gma_obstaculos_rd_data_in[w])
                    vizinho_invalido[w] <= 1'b1;
            end
        end
        // Vizinho já estabelecido
        else if (state == ST_LER_ESTABELECIDO && lvv_estabelecido_ready_in) begin
            for (w = 0; w < NUM_READ_PORTS; w = w +1) begin
                if (ge_estabelecidos_rd_data_in[w])
                    vizinho_invalido[w] <= 1'b1;
            end
        end
        // Vizinho inexistente
        else if (state == ST_SALVAR_STATUS) begin
            for (w = 0; w < NUM_READ_PORTS; w = w +1) begin
                // Pega o ea_obstaculos_rd_addr_out pois ele é registrado internamente e não muda até esse estágio
                if (ea_obstaculos_rd_addr_out[w] == {ADDR_WIDTH{1'b1}})
                    vizinho_invalido[w] <= 1'b1;
            end
        end
    end
end

//*******************************************************
//Contator de subvizinhos
//*******************************************************
localparam COUNT_WIDTH = 4;
reg [COUNT_WIDTH-1:0] count_subvizinho;

assign todos_analisados = count_subvizinho == MAX_VIZINHOS-1;

always @(posedge clk or negedge rst_n) begin
   if (!rst_n) begin
      count_subvizinho <= {COUNT_WIDTH{1'b0}};
   end
   else begin
      if (state == ST_SALVAR_MENOR && next_state == ST_IDENTIFICAR_SUBVIZINHOS)
         count_subvizinho <= count_subvizinho +1'b1;
      else if (state == ST_IDLE) begin
         count_subvizinho <= {COUNT_WIDTH{1'b0}};
      end
   end
end

//*******************************************************
//Outputs
//*******************************************************
assign ea_anterior_out = endereco_aprovado;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        ea_ocupado_out <= 1'b0;
    end
    else begin
        if (lvv_escrever_aprovado_in) begin
            ea_ocupado_out <= 1'b1;
        end
        else if (ea_pronto_out) begin
            ea_ocupado_out <= 1'b0;
        end
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        ea_obstaculos_rd_enable_out <= 1'b0;
        for (w = 0; w < NUM_READ_PORTS; w = w +1) begin
            ea_obstaculos_rd_addr_out[w] <= {ADDR_WIDTH{1'b0}};
        end
    end
    else begin
        ea_obstaculos_rd_enable_out <= 1'b0;
        if (state == ST_LER_OBSTACULO || state == ST_LER_OBSTACULO_SUBVIZINHO)
            ea_obstaculos_rd_enable_out <= 1'b1;
        

        if (state == ST_LER_OBSTACULO)
            for (w = 0; w < NUM_READ_PORTS; w = w +1) begin
                ea_obstaculos_rd_addr_out[w] <= relacoes_aprovado_addr[w];
            end
        else if (state == ST_LER_OBSTACULO_SUBVIZINHO)
            for (w = 0; w < NUM_READ_PORTS; w = w +1) begin
                ea_obstaculos_rd_addr_out[w] <= relacoes_4d_addr[count_subvizinho][w];
            end
    end
end

assign ea_estabelecidos_rd_addr_out = ea_obstaculos_rd_addr_out;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        ea_estabelecido_rd_enable_out <= 1'b0;
    end
    else begin
        ea_estabelecido_rd_enable_out <= 1'b0;
        if (state == ST_LER_ESTABELECIDO)
            ea_estabelecido_rd_enable_out <= 1'b1;
    end
end

assign ea_relacoes_rd_addr_out = ea_obstaculos_rd_addr_out;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        ea_relacoes_rd_enable_out <= 1'b0;
    end
    else begin
        ea_relacoes_rd_enable_out <= 1'b0;
        if (state == ST_LER_RELACOES) begin
            ea_relacoes_rd_enable_out <= 1'b1;
        end
    end
end
//*******************************************************
//Instantiations
//*******************************************************

endmodule