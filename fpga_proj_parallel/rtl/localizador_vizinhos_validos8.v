//==================================================================================================
//  Filename      : localizador_vizinhos_validos8.v
//  Created On    : 2022-11-22 10:07:48
//  Last Modified : 2023-02-01 11:35:45
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
                  parameter NUM_READ_PORTS = 8,
                  parameter NUM_NA = 4,
                  parameter NUM_EA = 8,
                  parameter CUSTO_WIDTH = 4,
                  parameter UMA_RELACAO_WIDTH = ADDR_WIDTH+CUSTO_WIDTH,
                  parameter RELACOES_DATA_WIDTH = MAX_VIZINHOS*(UMA_RELACAO_WIDTH)
            )
            (/*autoport*/
                input clk,
                input rst_n,
                input aa_ocupado_in,
                input aa_pronto_in,
                input aa_atualizar_ready_in,
                input [NUM_NA-1:0] aa_aprovado_in,
                input [ADDR_WIDTH*NUM_NA-1:0] aa_endereco_in,
                input [ADDR_WIDTH*NUM_NA-1:0] aa_anterior_data_in,
                input [DISTANCIA_WIDTH*NUM_NA-1:0] aa_distancia_in,
                input cme_expandir_in,
                // Atualizando o avaliador de ativos
                output lvv_desativar_out,
                output lvv_atualizar_out,
                output [NUM_READ_PORTS-1:0] lvv_vizinho_valido_out,
                output [NUM_READ_PORTS*ADDR_WIDTH-1:0] lvv_endereco_out,
                output [NUM_READ_PORTS*CUSTO_WIDTH-1:0] lvv_menor_vizinho_out,
                output [NUM_READ_PORTS*DISTANCIA_WIDTH-1:0] lvv_distancia_out,
                output [ADDR_WIDTH-1:0] lvv_anterior_out,
                // Atualizando os estabelecidos
                output reg lvv_estabelecidos_write_en_out,
                output reg [ADDR_WIDTH-1:0] lvv_estabelecidos_write_addr_out,
                // Atualizando anterior
                output reg [ADDR_WIDTH-1:0] lvv_anterior_data_out,
                // Indicando que o processamento atual termninou
                output lvv_pronto_out,
                // Lendo relações
                input [RELACOES_DATA_WIDTH*NUM_READ_PORTS-1:0] gma_relacoes_read_data_in,
                output [ADDR_WIDTH*NUM_READ_PORTS-1:0] lvv_relacoes_read_addr_out,
                // Lendo obstáculos
                output [ADDR_WIDTH*NUM_READ_PORTS-1:0] lvv_obstaculos_read_addr_out,
                input [NUM_READ_PORTS-1:0] gma_obstaculos_read_data_in,
                //lendo estabelecidos
                output [ADDR_WIDTH*NUM_READ_PORTS-1:0] lvv_estabelecidos_read_addr_out,
                input [NUM_READ_PORTS-1:0] ge_read_data_in
        );
//*******************************************************
//Internal
//*******************************************************
integer w, k;
genvar i;
//localparam
localparam STATE_WIDTH = 4;
localparam ST_IDLE = 4'd0,
           ST_ATUALIZAR_ESTABILIZAR = 4'd6,
           ST_ESTABILIZAR = 4'd1,
           ST_ATUALIZAR = 4'd2,
           ST_EXPANDIR_APROVADO = 4'd3,
           ST_EA_OCUPADO = 4'd4,
           ST_FINALIZAR = 4'd5;
localparam EA_GL_ADDR_WIDTH = ADDR_WIDTH*NUM_READ_PORTS;
localparam COUNT_PROXIMO_APROVADO_WIDTH = $clog2(NUM_NA);
localparam COUNT_EA_WIDTH = $clog2(NUM_EA);
//registers
reg [COUNT_EA_WIDTH-1:0] count_ea;
reg [STATE_WIDTH-1:0] state, next_state;
reg [NUM_NA-1:0] aprovados_reg;
reg [COUNT_PROXIMO_APROVADO_WIDTH-1:0] proximo_aprovado;

reg [NUM_EA-1:0] lvv_escrever_aprovado;
reg [ADDR_WIDTH-1:0] lvv_aprovado_addr;
reg [DISTANCIA_WIDTH-1:0] lvv_aprovado_distancia;
//wires
wire [ADDR_WIDTH-1:0] aa_endereco_2d [0:NUM_NA-1];
wire [ADDR_WIDTH-1:0] aa_anterior_data_2d [0:NUM_NA-1];
wire [DISTANCIA_WIDTH-1:0] aa_distancia_2d [0:NUM_NA-1];
wire tem_aprovado;

wire [RELACOES_DATA_WIDTH*NUM_READ_PORTS-1:0] gl_relacoes_rd_data;
wire [NUM_READ_PORTS-1:0] gl_obstaculos_rd_data;
wire [NUM_READ_PORTS-1:0] gl_estabelecidos_rd_data;

wire [NUM_EA-1:0] gl_relacoes_ready;
wire [NUM_EA-1:0] lvv_obstaculos_ready;
wire [NUM_EA-1:0] lvv_estabelecido_ready;

wire [NUM_EA-1:0] ea_relacoes_rd_enable;
wire [NUM_EA-1:0] ea_obstaculos_rd_enable;
wire [NUM_EA-1:0] ea_estabelecido_rd_enable;

wire [ADDR_WIDTH*NUM_READ_PORTS*NUM_EA-1:0] ea_relacoes_rd_addr;
wire [ADDR_WIDTH*NUM_READ_PORTS*NUM_EA-1:0] ea_obstaculos_rd_addr;
wire [ADDR_WIDTH*NUM_READ_PORTS*NUM_EA-1:0] ea_estabelecidos_rd_addr;

wire [ADDR_WIDTH*NUM_READ_PORTS-1:0] ea_relacoes_rd_addr_2d [0:NUM_EA-1];
wire [ADDR_WIDTH*NUM_READ_PORTS-1:0] ea_obstaculos_rd_addr_2d [0:NUM_EA-1];
wire [ADDR_WIDTH*NUM_READ_PORTS-1:0] ea_estabelecidos_rd_addr_2d [0:NUM_EA-1];
wire todos_ea_prontos;

wire [NUM_EA-1:0] oe_atualizar_ready;
wire [NUM_EA-1:0] ea_pronto;
wire [NUM_EA-1:0] ea_ocupado;
wire [NUM_EA-1:0] ea_atualizar;
wire [NUM_READ_PORTS-1:0] ea_vizinho_valido [0:NUM_EA-1];
wire [ADDR_WIDTH*NUM_READ_PORTS-1:0] ea_endereco [0:NUM_EA-1];
wire [CUSTO_WIDTH*NUM_READ_PORTS-1:0] ea_menor_vizinho [0:NUM_EA-1];
wire [DISTANCIA_WIDTH*NUM_READ_PORTS-1:0] ea_distancia [0:NUM_EA-1];
wire [ADDR_WIDTH-1:0] ea_anterior [0:NUM_EA-1];

wire [NUM_READ_PORTS*NUM_EA-1:0] ea_vizinho_valido_1d;
wire [ADDR_WIDTH*NUM_READ_PORTS*NUM_EA-1:0] ea_endereco_1d;
wire [CUSTO_WIDTH*NUM_READ_PORTS*NUM_EA-1:0] ea_menor_vizinho_1d;
wire [DISTANCIA_WIDTH*NUM_READ_PORTS*NUM_EA-1:0] ea_distancia_1d;
wire [ADDR_WIDTH*NUM_EA-1:0] ea_anterior_1d;
wire todos_ea_ocupados;
//*******************************************************
//Sinais de controle
//*******************************************************
assign tem_aprovado = aprovados_reg != 0;
assign escrevendo_aprovado = |lvv_escrever_aprovado;
assign todos_ea_prontos = &ea_pronto;
assign todos_ea_ocupados = &ea_ocupado;
//*******************************************************
// Convertendo sinais
//*******************************************************
// entrada para 2d
generate
    for (i = 0; i < NUM_NA; i = i + 1) begin:convert_dimension_in
        assign aa_endereco_2d[i] = aa_endereco_in[ADDR_WIDTH*i+ADDR_WIDTH-1:ADDR_WIDTH*i];
        assign aa_anterior_data_2d[i] = aa_anterior_data_in[ADDR_WIDTH*i+ADDR_WIDTH-1:ADDR_WIDTH*i];
        assign aa_distancia_2d[i] = aa_distancia_in[DISTANCIA_WIDTH*i+DISTANCIA_WIDTH-1:DISTANCIA_WIDTH*i];
    end
endgenerate

// endereços dos expansores de aprovado para o gerenciador de leitura
generate
    for (i = 0; i < NUM_EA; i = i + 1) begin:convert_dimension_ea_gl
        assign ea_relacoes_rd_addr[EA_GL_ADDR_WIDTH*i+EA_GL_ADDR_WIDTH-1:EA_GL_ADDR_WIDTH*i] = ea_relacoes_rd_addr_2d[i];
        assign ea_obstaculos_rd_addr[EA_GL_ADDR_WIDTH*i+EA_GL_ADDR_WIDTH-1:EA_GL_ADDR_WIDTH*i] = ea_obstaculos_rd_addr_2d[i];
        assign ea_estabelecidos_rd_addr[EA_GL_ADDR_WIDTH*i+EA_GL_ADDR_WIDTH-1:EA_GL_ADDR_WIDTH*i] = ea_estabelecidos_rd_addr_2d[i];
    end
endgenerate

generate
    for (i = 0; i < NUM_EA; i = i + 1) begin:convert_dimension_ea_g2
        assign ea_vizinho_valido_1d[NUM_READ_PORTS*i+NUM_READ_PORTS-1:NUM_READ_PORTS*i] = ea_vizinho_valido[i];
        assign ea_endereco_1d[ADDR_WIDTH*NUM_READ_PORTS*i+ADDR_WIDTH*NUM_READ_PORTS-1:ADDR_WIDTH*NUM_READ_PORTS*i] = ea_endereco[i];
        assign ea_menor_vizinho_1d[CUSTO_WIDTH*NUM_READ_PORTS*i+CUSTO_WIDTH*NUM_READ_PORTS-1:CUSTO_WIDTH*NUM_READ_PORTS*i] = ea_menor_vizinho[i];
        assign ea_distancia_1d[DISTANCIA_WIDTH*NUM_READ_PORTS*i+DISTANCIA_WIDTH*NUM_READ_PORTS-1:DISTANCIA_WIDTH*NUM_READ_PORTS*i] = ea_distancia[i];
        assign ea_anterior_1d[ADDR_WIDTH*i+ADDR_WIDTH-1:ADDR_WIDTH*i] = ea_anterior[i];
    end
endgenerate

always @(posedge clk or negedge rst_n) begin
   if (!rst_n) begin
      count_ea <= {COUNT_EA_WIDTH{1'b0}};
   end
   else begin
      for (w = 0; w < NUM_NA; w = w +1) begin
         if (ea_ocupado[w]==0)
             count_ea <= w;
      end
   end
end

//*******************************************************
//Contando os ea ocupados
//*******************************************************
reg [COUNT_EA_WIDTH-1:0] num_ea_ocupados;
wire ea_nao_cheio;
always @(*) begin
    num_ea_ocupados = 0;
    for (w = 0; w < NUM_EA; w = w +1) begin
        num_ea_ocupados = num_ea_ocupados + ea_ocupado[w];
    end
end

assign ea_nao_cheio = num_ea_ocupados < NUM_EA-2;

//*******************************************************
//Escrevendo no expansor de aprovado
//*******************************************************
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        lvv_escrever_aprovado <= {NUM_EA{1'b0}};
        lvv_aprovado_addr <= {ADDR_WIDTH{1'b0}};
        lvv_aprovado_distancia <= {DISTANCIA_WIDTH{1'b0}};
    end
    else begin
        lvv_escrever_aprovado <= {NUM_EA{1'b0}};
        if (state == ST_EXPANDIR_APROVADO) begin
            lvv_escrever_aprovado[count_ea] <= 1'b1; 
            lvv_aprovado_addr <= aa_endereco_2d[proximo_aprovado];
            lvv_aprovado_distancia <= aa_distancia_2d[proximo_aprovado];
        end
    end
end
//*******************************************************
//analisando entrada
//*******************************************************
// Salvando a posição dos nós aprovados
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        aprovados_reg <= 0;
    end
    else begin
        if (state==ST_IDLE || (state == ST_ESTABILIZAR && !tem_aprovado))
            aprovados_reg <= aa_aprovado_in;
        
        else if (lvv_estabelecidos_write_en_out || state == ST_EXPANDIR_APROVADO)
            aprovados_reg[proximo_aprovado] <= 1'b0;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        proximo_aprovado <= {COUNT_PROXIMO_APROVADO_WIDTH{1'b0}};
    end
    else begin
        proximo_aprovado <= {COUNT_PROXIMO_APROVADO_WIDTH{1'b0}};
        for (w = 0; w < NUM_NA; w = w +1) begin
            if (aprovados_reg[w]==1)
                proximo_aprovado <= w;
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
            if (cme_expandir_in && !lvv_pronto_out)
                next_state = ST_ATUALIZAR_ESTABILIZAR;
        ST_ATUALIZAR_ESTABILIZAR:
                next_state = ST_ESTABILIZAR;
        // 1
        ST_ESTABILIZAR:
            if (!tem_aprovado)
                next_state = ST_ATUALIZAR;
        // 2
        ST_ATUALIZAR:
            next_state = ST_EXPANDIR_APROVADO;
        // 3
        ST_EXPANDIR_APROVADO:
            if (!tem_aprovado)
                next_state = ST_FINALIZAR;
            else if (!todos_ea_ocupados && ea_nao_cheio)
                next_state = ST_EXPANDIR_APROVADO;
            else
                next_state = ST_EA_OCUPADO;
        // 4
        ST_EA_OCUPADO:
            if (!tem_aprovado)
                next_state = ST_FINALIZAR;
            else if (!todos_ea_ocupados && !escrevendo_aprovado)
                next_state = ST_EXPANDIR_APROVADO;
        // 5
        ST_FINALIZAR:
            if (todos_ea_prontos)
                next_state = ST_IDLE;
    endcase
end
//*******************************************************
//Outputs
//*******************************************************
// assign lvv_atualizar_out = 0;
assign lvv_desativar_out = state == ST_ESTABILIZAR;
assign lvv_pronto_out = state == ST_FINALIZAR && todos_ea_prontos && aa_pronto_in; 

// TODO: lvv_estabelecidos_write_en_out Está demorando ativo dois pulsos de clock, não é um problema mas talvez seja bom otimizar
always @(*) begin
    lvv_estabelecidos_write_en_out = 1'b0;
    // TODO: Tamanhos diferentes
    lvv_estabelecidos_write_addr_out = aa_endereco_2d[proximo_aprovado];
    lvv_anterior_data_out = aa_anterior_data_2d[proximo_aprovado];
    if (state == ST_ESTABILIZAR) begin
        lvv_estabelecidos_write_en_out = 1'b1;
    end
end

//*******************************************************
//Instantiations
//*******************************************************
generate
    for (i = 0; i < NUM_EA; i = i + 1) begin:gen_ea
        expansor_aprovados
            #(  
                .ADDR_WIDTH(ADDR_WIDTH),
                .DISTANCIA_WIDTH(DISTANCIA_WIDTH),
                .MAX_VIZINHOS(MAX_VIZINHOS),
                .NUM_READ_PORTS(NUM_READ_PORTS),
                .CUSTO_WIDTH(CUSTO_WIDTH),
                .UMA_RELACAO_WIDTH(UMA_RELACAO_WIDTH),
                .RELACOES_DATA_WIDTH(RELACOES_DATA_WIDTH)
            )
                expansor_aprovados_u
            (/*autoport*/
                .clk(clk),
                .rst_n(rst_n),
                .lvv_escrever_aprovado_in(lvv_escrever_aprovado[i]),
                .lvv_aprovado_addr_in(lvv_aprovado_addr),
                .lvv_aprovado_distancia_in(lvv_aprovado_distancia),
                .lvv_relacoes_ready_in(gl_relacoes_ready[i]),
                .gma_relacoes_rd_data_in(gl_relacoes_rd_data),
                .ea_relacoes_rd_enable_out(ea_relacoes_rd_enable[i]),
                .ea_relacoes_rd_addr_out(ea_relacoes_rd_addr_2d[i]),
                .lvv_obstaculos_ready_in(lvv_obstaculos_ready[i]),
                .gma_obstaculos_rd_data_in(gl_obstaculos_rd_data),
                .ea_obstaculos_rd_enable_out(ea_obstaculos_rd_enable[i]),
                .ea_obstaculos_rd_addr_out(ea_obstaculos_rd_addr_2d[i]),
                .lvv_estabelecido_ready_in(lvv_estabelecido_ready[i]),
                .ge_estabelecidos_rd_data_in(gl_estabelecidos_rd_data),
                .ea_estabelecido_rd_enable_out(ea_estabelecido_rd_enable[i]),
                .ea_estabelecidos_rd_addr_out(ea_estabelecidos_rd_addr_2d[i]),
                .aa_atualizar_ready_in(oe_atualizar_ready[i]),
                .ea_pronto_out(ea_pronto[i]),
                .ea_ocupado_out(ea_ocupado[i]),
                .ea_vizinho_valido_out(ea_vizinho_valido[i]),
                .ea_atualizar_out(ea_atualizar[i]),
                .ea_endereco_out(ea_endereco[i]),
                .ea_menor_vizinho_out(ea_menor_vizinho[i]),
                .ea_distancia_out(ea_distancia[i]),
                .ea_anterior_out(ea_anterior[i])
            );
        end
endgenerate

ordenador_escritas
        #(
            .ADDR_WIDTH(ADDR_WIDTH),
            .DISTANCIA_WIDTH(DISTANCIA_WIDTH),
            .NUM_READ_PORTS(NUM_READ_PORTS),
            .NUM_EA(NUM_EA),
            .CUSTO_WIDTH(CUSTO_WIDTH)
        )
        ordenador_escritas_u0
        (/*autoport*/
            .clk(clk),
            .rst_n(rst_n),
            .aa_ocupado_in(aa_ocupado_in),
            .ea_atualizar_ready_out(oe_atualizar_ready),
            .ea_atualizar_in(ea_atualizar),
            .ea_vizinho_valido_in(ea_vizinho_valido_1d),
            .ea_endereco_in(ea_endereco_1d),
            .ea_menor_vizinho_in(ea_menor_vizinho_1d),
            .ea_distancia_in(ea_distancia_1d),
            .ea_anterior_in(ea_anterior_1d),
            .aa_atualizar_ready_in(aa_atualizar_ready_in),
            .oe_atualizar_out(lvv_atualizar_out),
            .oe_vizinho_valido_out(lvv_vizinho_valido_out),
            .oe_endereco_out(lvv_endereco_out),
            .oe_menor_vizinho_out(lvv_menor_vizinho_out),
            .oe_distancia_out(lvv_distancia_out),
            .oe_anterior_out(lvv_anterior_out)
        );

gerenciador_leituras
    #(
        .NUM_READ_PORTS(NUM_READ_PORTS),
        .NUM_EA(NUM_EA),
        .DATA_WIDH(RELACOES_DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    )
    gl_relacoes
    (/*autoport*/
        .clk(clk),
        .rst_n(rst_n),
        .lvv_read_en_in(ea_relacoes_rd_enable),
        .lvv_read_addr_in(ea_relacoes_rd_addr),
        .ready_out(gl_relacoes_ready),
        .read_data_out(gl_relacoes_rd_data),
        .read_addr_out(lvv_relacoes_read_addr_out),
        .mem_read_data_in(gma_relacoes_read_data_in)
    );

gerenciador_leituras
    #(
        .NUM_READ_PORTS(NUM_READ_PORTS),
        .NUM_EA(NUM_EA),
        .DATA_WIDH(1'b1),
        .ADDR_WIDTH(ADDR_WIDTH)
    )
    gl_obstaculos
    (/*autoport*/
        .clk(clk),
        .rst_n(rst_n),
        .lvv_read_en_in(ea_obstaculos_rd_enable),
        .lvv_read_addr_in(ea_obstaculos_rd_addr),
        .ready_out(lvv_obstaculos_ready),
        .read_data_out(gl_obstaculos_rd_data),
        .read_addr_out(lvv_obstaculos_read_addr_out),
        .mem_read_data_in(gma_obstaculos_read_data_in)
    );

gerenciador_leituras
    #(
        .NUM_READ_PORTS(NUM_READ_PORTS),
        .NUM_EA(NUM_EA),
        .DATA_WIDH(1'b1),
        .ADDR_WIDTH(ADDR_WIDTH)
    )
    gl_estabelecidos
    (/*autoport*/
        .clk(clk),
        .rst_n(rst_n),
        .lvv_read_en_in(ea_estabelecido_rd_enable),
        .lvv_read_addr_in(ea_estabelecidos_rd_addr),
        .ready_out(lvv_estabelecido_ready),
        .read_data_out(gl_estabelecidos_rd_data),
        .read_addr_out(lvv_estabelecidos_read_addr_out),
        .mem_read_data_in(ge_read_data_in)
    );

endmodule 