//==================================================================================================
//  Filename      : expansor_aprovados.v
//  Created On    : 2022-11-23 08:07:40
//  Last Modified : 2023-02-01 08:55:07
//  Revision      : 
//  Author        : Linton Esteves
//  Company       : UFBA
//  Email         : lintonthiago@gmail.com
//
//  Description   : 
// relacoes_4d_custo_reg e relacoes_4d_addr foram criados como memorias locais para diminuir o acesso às memorias
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
            input [ADDR_WIDTH-1:0] lvv_aprovado_addr_in,
            input [DISTANCIA_WIDTH-1:0] lvv_aprovado_distancia_in,
            // Lendo relações de um nó
            input lvv_relacoes_ready_in,
            input [RELACOES_DATA_WIDTH*NUM_READ_PORTS-1:0] gma_relacoes_rd_data_in,
            output reg ea_relacoes_rd_enable_out,
            output [ADDR_WIDTH*NUM_READ_PORTS-1:0] ea_relacoes_rd_addr_out,
            // Lendo obstáculos
            input lvv_obstaculos_ready_in,
            input [NUM_READ_PORTS-1:0] gma_obstaculos_rd_data_in,
            output reg ea_obstaculos_rd_enable_out,
            output [ADDR_WIDTH*NUM_READ_PORTS-1:0] ea_obstaculos_rd_addr_out,
            //lendo estabelecidos
            input lvv_estabelecido_ready_in,
            input [NUM_READ_PORTS-1:0] ge_estabelecidos_rd_data_in,
            output reg ea_estabelecido_rd_enable_out,
            output [ADDR_WIDTH*NUM_READ_PORTS-1:0] ea_estabelecidos_rd_addr_out,
            // Enviando nó salvo
            input aa_atualizar_ready_in,
            output reg ea_pronto_out,
            output reg ea_ocupado_out,
            output reg ea_atualizar_out,
            output reg [NUM_READ_PORTS-1:0] ea_vizinho_valido_out,
            output [ADDR_WIDTH*NUM_READ_PORTS-1:0] ea_endereco_out,
            output [CUSTO_WIDTH*NUM_READ_PORTS-1:0] ea_menor_vizinho_out,
            output [DISTANCIA_WIDTH*NUM_READ_PORTS-1:0] ea_distancia_out,
            output [ADDR_WIDTH-1:0] ea_anterior_out
        );
//*******************************************************
//Internal
//*******************************************************
genvar i, j;
integer w;
//Local Parameters
localparam STATE_WIDTH = 4;
localparam ST_IDLE = 4'd0,
           ST_LER_APROVADO = 4'd1,
           ST_LER_OBSTACULO = 4'd2,
           ST_LER_ESTABELECIDO = 4'd3,
           ST_SALVAR_STATUS = 4'd4,
           ST_LER_RELACOES = 4'd5,
           ST_IDENTIFICAR_SUBVIZINHOS = 4'd6,
           ST_LER_OBSTACULO_SUBVIZINHO = 4'd7,
           ST_SALVAR_MENOR = 4'd8,
           ST_FINALIZAR = 4'd9;

localparam COUNT_DISTANCIA_WIDTH = 4;
localparam COUNT_WIDTH = 4;
//Wires
wire [RELACOES_DATA_WIDTH-1:0] relacoes_2d [0:NUM_READ_PORTS-1];
wire [UMA_RELACAO_WIDTH-1:0] relacoes_4d [0:MAX_VIZINHOS*NUM_READ_PORTS-1];
wire [CUSTO_WIDTH-1:0] relacoes_4d_custo [0:MAX_VIZINHOS*NUM_READ_PORTS-1];
wire [ADDR_WIDTH-1:0] relacoes_4d_addr [0:MAX_VIZINHOS*NUM_READ_PORTS-1];
wire salvou_todos, todos_analisados;
wire [UMA_RELACAO_WIDTH-1:0] relacoes_aprovado_2d [0:MAX_VIZINHOS-1];
wire [CUSTO_WIDTH-1:0] relacoes_aprovado_custo [0:MAX_VIZINHOS-1];
wire [ADDR_WIDTH-1:0] relacoes_aprovado_addr [0:MAX_VIZINHOS-1];

//Registers
reg [RELACOES_DATA_WIDTH-1:0] relacoes_aprovado_reg;
reg [ADDR_WIDTH-1:0] read_addr_2d [0:NUM_READ_PORTS-1];
reg [COUNT_WIDTH-1:0] count_subvizinho;
reg [STATE_WIDTH-1:0] state, next_state;
reg [ADDR_WIDTH-1:0] endereco_aprovado;
reg [DISTANCIA_WIDTH-1:0] distancia_aprovado;
reg [MAX_VIZINHOS-1:0] vizinho_salvo;
reg [COUNT_DISTANCIA_WIDTH-1:0] count_distancia;
reg [DISTANCIA_WIDTH-1:0] distancias_reg [MAX_VIZINHOS-1:0];
reg [CUSTO_WIDTH-1:0] menor_vizinho_reg [MAX_VIZINHOS-1:0];

reg [CUSTO_WIDTH-1:0] relacoes_4d_custo_reg [0:MAX_VIZINHOS*NUM_READ_PORTS-1];
reg [ADDR_WIDTH-1:0] relacoes_4d_addr_reg [0:MAX_VIZINHOS*NUM_READ_PORTS-1];
//*******************************************************
//Convertendo dimensões
//*******************************************************

generate
    for (i = 0; i < NUM_READ_PORTS; i = i + 1) begin:convert_1d_out
        assign ea_obstaculos_rd_addr_out[ADDR_WIDTH*i+ADDR_WIDTH-1:ADDR_WIDTH*i] = read_addr_2d[i];
        assign ea_relacoes_rd_addr_out[ADDR_WIDTH*i+ADDR_WIDTH-1:ADDR_WIDTH*i] = read_addr_2d[i];
        assign ea_estabelecidos_rd_addr_out[ADDR_WIDTH*i+ADDR_WIDTH-1:ADDR_WIDTH*i] = read_addr_2d[i];
    end
endgenerate

generate
    for (i = 0; i < NUM_READ_PORTS; i = i + 1) begin:convert_1d_in
        assign relacoes_2d[i] = gma_relacoes_rd_data_in[RELACOES_DATA_WIDTH*i+RELACOES_DATA_WIDTH-1:RELACOES_DATA_WIDTH*i];
    end
endgenerate

generate
    for (i = 0; i < MAX_VIZINHOS; i = i + 1) begin:convert_2d_4d_in
        assign relacoes_aprovado_2d[MAX_VIZINHOS-1-i] = relacoes_aprovado_reg[UMA_RELACAO_WIDTH*i+UMA_RELACAO_WIDTH-1:UMA_RELACAO_WIDTH*i];
        assign relacoes_aprovado_custo[i] = relacoes_aprovado_2d[i][CUSTO_WIDTH-1:0];
        assign relacoes_aprovado_addr[i] = relacoes_aprovado_2d[i][ADDR_WIDTH-1+CUSTO_WIDTH:CUSTO_WIDTH];
    end
endgenerate


// Todo: testar isso aqui  
generate
    for (j = 0; j < MAX_VIZINHOS; j = j + 1) begin:convert_4d_in
        for (i = 0; i < NUM_READ_PORTS; i = i + 1) begin:convert_2d_in
            assign relacoes_4d[j*MAX_VIZINHOS+(NUM_READ_PORTS-i-1)] = relacoes_2d[j][UMA_RELACAO_WIDTH*i+UMA_RELACAO_WIDTH-1:UMA_RELACAO_WIDTH*i];
            
            assign relacoes_4d_custo[j*MAX_VIZINHOS+i] = relacoes_4d[j*MAX_VIZINHOS+i][CUSTO_WIDTH-1:0];
            assign relacoes_4d_addr[j*MAX_VIZINHOS+i] = relacoes_4d[j*MAX_VIZINHOS+i][ADDR_WIDTH-1+CUSTO_WIDTH:CUSTO_WIDTH];
        end
    end
endgenerate

assign ea_anterior_out = endereco_aprovado;

generate
    for (i = 0; i < NUM_READ_PORTS; i = i + 1) begin:convert_2d_out
        assign ea_distancia_out[DISTANCIA_WIDTH*i+DISTANCIA_WIDTH-1:DISTANCIA_WIDTH*i] = distancias_reg[i];
        assign ea_menor_vizinho_out[CUSTO_WIDTH*i+CUSTO_WIDTH-1:CUSTO_WIDTH*i] = menor_vizinho_reg[i];
        assign ea_endereco_out[ADDR_WIDTH*i+ADDR_WIDTH-1:ADDR_WIDTH*i] = relacoes_aprovado_addr[i];
    end
endgenerate



always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (w = 0; w < MAX_VIZINHOS*NUM_READ_PORTS; w = w +1) begin
            relacoes_4d_custo_reg[w] <= {DISTANCIA_WIDTH{1'b1}};
            relacoes_4d_addr_reg[w] <= {DISTANCIA_WIDTH{1'b1}};
        end
    end
    else begin
        for (w = 0; w < MAX_VIZINHOS*NUM_READ_PORTS; w = w +1) begin
            if (state == ST_LER_RELACOES) begin
                relacoes_4d_addr_reg[w] <= relacoes_4d_addr[w];
                relacoes_4d_custo_reg[w] <= relacoes_4d_custo[w];
            end
        end
    end
end

//*******************************************************
//Sinais de controle
//*******************************************************
// Quando não existe nenhum vizinho válido ou todos já foram salvos
assign salvou_todos = &(vizinho_salvo | &ea_vizinho_valido_out);

//*******************************************************
//General Purpose Signals
//*******************************************************
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        endereco_aprovado <= {ADDR_WIDTH{1'b0}};
        distancia_aprovado <= {DISTANCIA_WIDTH{1'b0}};
    end
    else begin
        if (lvv_escrever_aprovado_in) begin
            endereco_aprovado <= lvv_aprovado_addr_in;
            distancia_aprovado <= lvv_aprovado_distancia_in;
        end
    end
end

// Lendo as relações do nó aprovado, sempre será na posição zero
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        relacoes_aprovado_reg <= {{1'b0}};
    end
    else begin
        if (state == ST_LER_APROVADO && lvv_relacoes_ready_in)
            relacoes_aprovado_reg <= relacoes_2d[0];
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
        if (state != ST_IDLE) begin
            distancias_reg[count_distancia] <= distancia_aprovado + relacoes_aprovado_custo[count_distancia];
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
      if (state != ST_IDLE)
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
                    menor_vizinho_reg[w] <= relacoes_4d_custo_reg[count_subvizinho+w*NUM_READ_PORTS];
            end
        end
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        vizinho_salvo <= {NUM_READ_PORTS{1'b0}};
    end
    else begin
        // Removendo os nós inválidos 
        if (state == ST_LER_RELACOES) begin
            for (w = 0; w < NUM_READ_PORTS; w = w + 1) begin
                if (ea_vizinho_valido_out[w] == 1'b0)
                    vizinho_salvo[w] <= 1'b1;
                else
                    vizinho_salvo[w] <= 1'b0;
            end
        end
        if (state == ST_LER_OBSTACULO_SUBVIZINHO && lvv_obstaculos_ready_in == 1'b1) begin
            for (w = 0; w < NUM_READ_PORTS; w = w + 1) begin
                if (gma_obstaculos_rd_data_in[w] == 1'b0)
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
        // 0
        ST_IDLE:
            if (lvv_escrever_aprovado_in)
                next_state = ST_LER_APROVADO;
        // 1
        ST_LER_APROVADO:
            // Lendo as relações do nó aprovado
            if (lvv_relacoes_ready_in)
                next_state = ST_LER_OBSTACULO;
        // 2
        ST_LER_OBSTACULO:
            // Identificando quais relações são obstáculos
            if (lvv_obstaculos_ready_in)
                next_state = ST_LER_ESTABELECIDO;
        // 3
        ST_LER_ESTABELECIDO:
            // Identificando quais relações já estão estabelecidas
            if (lvv_estabelecido_ready_in)
                next_state = ST_SALVAR_STATUS;
        // 4
        ST_SALVAR_STATUS:
                next_state = ST_LER_RELACOES;
        // 5
        ST_LER_RELACOES:
            if (lvv_relacoes_ready_in)
                next_state = ST_IDENTIFICAR_SUBVIZINHOS;
        // 6
        ST_IDENTIFICAR_SUBVIZINHOS:
                next_state = ST_LER_OBSTACULO_SUBVIZINHO;
        // 7
        ST_LER_OBSTACULO_SUBVIZINHO:
            if (lvv_obstaculos_ready_in)
                next_state = ST_SALVAR_MENOR;
        // 8
        ST_SALVAR_MENOR:
            if (salvou_todos || todos_analisados)
                next_state = ST_FINALIZAR;
            else
                next_state = ST_IDENTIFICAR_SUBVIZINHOS;
        // 9
        ST_FINALIZAR:
            if (aa_atualizar_ready_in)
                next_state = ST_IDLE;
    endcase
end

//*******************************************************
//Controle de vizinhos válidos
//*******************************************************
// Identifica os vizinhos do nó ativo que não são válidos
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        ea_vizinho_valido_out <= {NUM_READ_PORTS{1'b0}};
    end
    else begin
        if (state == ST_IDLE) begin
            ea_vizinho_valido_out <= {NUM_READ_PORTS{1'b1}};
        end
        // Vizinho que é obstáculo
        else if (state == ST_LER_OBSTACULO && lvv_obstaculos_ready_in) begin
            for (w = 0; w < NUM_READ_PORTS; w = w +1) begin
                if (gma_obstaculos_rd_data_in[w])
                    ea_vizinho_valido_out[w] <= 1'b0;
            end
        end
        // Vizinho já estabelecido
        else if (state == ST_LER_ESTABELECIDO && lvv_estabelecido_ready_in) begin
            for (w = 0; w < NUM_READ_PORTS; w = w +1) begin
                if (ge_estabelecidos_rd_data_in[w])
                    ea_vizinho_valido_out[w] <= 1'b0;
            end
        end
        // Vizinho inexistente
        else if (state == ST_SALVAR_STATUS) begin
            for (w = 0; w < NUM_READ_PORTS; w = w +1) begin
                // Pega o ea_obstaculos_rd_addr_out pois ele é registrado internamente e não muda até esse estágio
                if (relacoes_aprovado_addr[w] == {ADDR_WIDTH{1'b1}})
                    ea_vizinho_valido_out[w] <= 1'b0;
            end
        end
    end
end

//*******************************************************
//Contator de subvizinhos
//*******************************************************
assign todos_analisados = count_subvizinho == MAX_VIZINHOS-1;

always @(posedge clk or negedge rst_n) begin
   if (!rst_n) begin
      count_subvizinho <= {COUNT_WIDTH{1'b0}};
   end
   else begin
   // TODO: Analisar
      if (state == ST_SALVAR_MENOR)
         count_subvizinho <= count_subvizinho + 1'b1;
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
        ea_pronto_out <= 1'b1;
    end
    else begin
        if (state == ST_IDLE && !lvv_escrever_aprovado_in) begin
            ea_pronto_out <= 1'b1;
        end
        else begin
            ea_pronto_out <= 1'b0;
        end
    end
end

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
    end
    else begin
        ea_obstaculos_rd_enable_out <= 1'b0;
        if ((state == ST_LER_OBSTACULO || state == ST_LER_OBSTACULO_SUBVIZINHO) && !lvv_obstaculos_ready_in)
            ea_obstaculos_rd_enable_out <= 1'b1;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (w = 0; w < NUM_READ_PORTS; w = w +1) begin
            read_addr_2d[w] <= {ADDR_WIDTH{1'b0}};
        end
    end
    else begin
        if (state == ST_LER_APROVADO)
            for (w = 0; w < NUM_READ_PORTS; w = w +1) begin
                read_addr_2d[0] <= endereco_aprovado;
            end
        else if (state == ST_LER_OBSTACULO)
            for (w = 0; w < NUM_READ_PORTS; w = w +1) begin
                read_addr_2d[w] <= relacoes_aprovado_addr[w];
            end
        else if (state == ST_LER_OBSTACULO_SUBVIZINHO)
            for (w = 0; w < NUM_READ_PORTS; w = w +1) begin
                read_addr_2d[w] <= relacoes_4d_addr_reg[count_subvizinho+w*NUM_READ_PORTS];
            end
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        ea_estabelecido_rd_enable_out <= 1'b0;
    end
    else begin
        ea_estabelecido_rd_enable_out <= 1'b0;
        if (state == ST_LER_ESTABELECIDO && !lvv_estabelecido_ready_in)
            ea_estabelecido_rd_enable_out <= 1'b1;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        ea_relacoes_rd_enable_out <= 1'b0;
    end
    else begin
        ea_relacoes_rd_enable_out <= 1'b0;
        if ((state == ST_LER_RELACOES || state == ST_LER_APROVADO) && !lvv_relacoes_ready_in) begin
            ea_relacoes_rd_enable_out <= 1'b1;
        end
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        ea_atualizar_out <= 1'b0;
    end
    else begin
        ea_atualizar_out <= 1'b0;
        if (state==ST_FINALIZAR && !aa_atualizar_ready_in)
            ea_atualizar_out <= 1'b1;
    end
end

endmodule