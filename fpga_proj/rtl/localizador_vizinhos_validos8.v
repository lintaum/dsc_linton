//==================================================================================================
//  Filename      : localizador_vizinhos_validos8.v
//  Created On    : 2022-11-22 10:07:48
//  Last Modified : 2022-11-29 14:12:53
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
                  parameter NUM_SOLICITACOES = NUM_EA,
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
                // Atualizando os estabelecidos
                output reg lvv_estabelecidos_write_en_out,
                output reg [ADDR_WIDTH-1:0] lvv_estabelecidos_write_addr_out,
                // Atualizando anterior
                output reg [ADDR_WIDTH-1:0] lvv_anterior_data_out,
                // Indicando que o processamento atual termninou
                output reg lvv_pronto_out,
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
           ST_ESTABILIZAR = 4'd1,
           ST_EXPANDIR_APROVADO = 4'd2,
           ST_EA_OCUPADO = 4'd3,
           ST_FINALIZAR = 4'd4;
localparam EA_GL_ADDR_WIDTH = ADDR_WIDTH*NUM_READ_PORTS;
//registers
reg [STATE_WIDTH-1:0] state, next_state;
reg [NUM_NA-1:0] aprovados_reg;
reg [ADDR_WIDTH-1:0] proximo_aprovado;
reg [ADDR_WIDTH-1:0] lvv_estabelecidos_write_addr; 
//wires
wire [ADDR_WIDTH-1:0] aa_endereco_2d [0:NUM_NA-1];
wire [ADDR_WIDTH-1:0] aa_anterior_data_2d [0:NUM_NA-1];
wire [DISTANCIA_WIDTH-1:0] aa_distancia_2d [0:NUM_NA-1];
wire tem_aprovado;

wire [RELACOES_DATA_WIDTH*NUM_READ_PORTS-1:0] gl_relacoes_rd_data;
wire [NUM_READ_PORTS-1:0] gl_obstaculos_rd_data;
wire [NUM_READ_PORTS-1:0] gl_estabelecidos_rd_data;

wire [NUM_SOLICITACOES-1:0] gl_relacoes_ready;
wire [NUM_SOLICITACOES-1:0] lvv_obstaculos_ready;
wire [NUM_SOLICITACOES-1:0] lvv_estabelecido_ready;

wire [NUM_SOLICITACOES-1:0] ea_relacoes_rd_enable;
wire [NUM_SOLICITACOES-1:0] ea_obstaculos_rd_enable;
wire [NUM_SOLICITACOES-1:0] ea_estabelecido_rd_enable;

wire [ADDR_WIDTH*NUM_READ_PORTS*NUM_SOLICITACOES-1:0] ea_relacoes_rd_addr;
wire [ADDR_WIDTH*NUM_READ_PORTS*NUM_SOLICITACOES-1:0] ea_obstaculos_rd_addr;
wire [ADDR_WIDTH*NUM_READ_PORTS*NUM_SOLICITACOES-1:0] ea_estabelecidos_rd_addr;

wire [ADDR_WIDTH*NUM_READ_PORTS-1:0] ea_relacoes_rd_addr_2d [0:NUM_SOLICITACOES-1];
wire [ADDR_WIDTH*NUM_READ_PORTS-1:0] ea_obstaculos_rd_addr_2d [0:NUM_SOLICITACOES-1];
wire [ADDR_WIDTH*NUM_READ_PORTS-1:0] ea_estabelecidos_rd_addr_2d [0:NUM_SOLICITACOES-1];
wire todos_ea_prontos;

reg [NUM_EA-1:0] lvv_escrever_aprovado;
reg [ADDR_WIDTH-1:0] lvv_aprovado_addr;
reg [DISTANCIA_WIDTH-1:0] lvv_aprovado_distancia;

wire [NUM_EA-1:0] aa_atualizar_ready;
wire [NUM_EA-1:0] ea_pronto;
wire [NUM_EA-1:0] ea_ocupado;
wire [NUM_EA-1:0] ea_atualizar;
wire [NUM_READ_PORTS-1:0] ea_vizinho_valido [0:NUM_EA-1];
wire [ADDR_WIDTH*NUM_READ_PORTS-1:0] ea_endereco [0:NUM_EA-1];
wire [CUSTO_WIDTH*NUM_READ_PORTS-1:0] ea_menor_vizinho [0:NUM_EA-1];
wire [DISTANCIA_WIDTH*NUM_READ_PORTS-1:0] ea_distancia [0:NUM_EA-1];
wire [ADDR_WIDTH-1:0] ea_anterior [0:NUM_EA-1];
//*******************************************************
//Sinais de controle
//*******************************************************
assign tem_aprovado = aprovados_reg != 0;
assign escrevendo_aprovado = |lvv_escrever_aprovado;
assign  todos_ea_prontos = &ea_pronto;
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
    for (i = 0; i < NUM_SOLICITACOES; i = i + 1) begin:convert_dimension_ea_gl
        assign ea_relacoes_rd_addr[EA_GL_ADDR_WIDTH*i+EA_GL_ADDR_WIDTH-1:EA_GL_ADDR_WIDTH*i] = ea_relacoes_rd_addr_2d[i];
        assign ea_obstaculos_rd_addr[EA_GL_ADDR_WIDTH*i+EA_GL_ADDR_WIDTH-1:EA_GL_ADDR_WIDTH*i] = ea_obstaculos_rd_addr_2d[i];
        assign ea_estabelecidos_rd_addr[EA_GL_ADDR_WIDTH*i+EA_GL_ADDR_WIDTH-1:EA_GL_ADDR_WIDTH*i] = ea_estabelecidos_rd_addr_2d[i];
    end
endgenerate

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
        if (state == ST_EXPANDIR_APROVADO)
            lvv_escrever_aprovado[proximo_aprovado] <= 1'b1;
            lvv_aprovado_addr <= aa_endereco_2d[proximo_aprovado];
            lvv_aprovado_distancia <= aa_distancia_2d[proximo_aprovado];
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
        
        if (lvv_estabelecidos_write_en_out || state == ST_EXPANDIR_APROVADO)
            aprovados_reg[proximo_aprovado] <= 1'b0;
    end
end

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
            if (cme_expandir_in && !lvv_pronto_out && !lvv_pronto_out)
                next_state = ST_ESTABILIZAR;
        ST_ESTABILIZAR:
            if (!tem_aprovado)
                next_state = ST_EXPANDIR_APROVADO;
        ST_EXPANDIR_APROVADO:
            next_state = ST_EA_OCUPADO;
        ST_EA_OCUPADO:
            next_state = ST_FINALIZAR;
        ST_FINALIZAR:
            if (todos_ea_prontos)
                next_state = ST_IDLE;
    endcase
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
        lvv_pronto_out <= 1'b0;
    end
    else begin
        
    end
end

always @(*) begin
    lvv_estabelecidos_write_en_out = 1'b0;
    // TODO: Tamanhos diferentes
    lvv_estabelecidos_write_addr_out = aa_endereco_2d[proximo_aprovado];
    lvv_anterior_data_out = aa_anterior_data_2d[proximo_aprovado];
    if (state == ST_ESTABILIZAR && !lvv_desativar_out && !aa_ocupado_in) begin
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
                .aa_atualizar_ready_in(aa_atualizar_ready[i]),
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

gerenciador_leituras
    #(
        .NUM_READ_PORTS(NUM_READ_PORTS),
        .NUM_SOLICITACOES(NUM_SOLICITACOES),
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
        .NUM_SOLICITACOES(NUM_SOLICITACOES),
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
        .NUM_SOLICITACOES(NUM_SOLICITACOES),
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