//==================================================================================================
//  Filename      : gerenciador_ativos.v
//  Created On    : 2022-08-26 08:34:19
//  Last Modified : 2023-01-16 08:32:17
//  Revision      : 
//  Author        : Linton Esteves
//  Company       : UFBA
//  Email         : lintonthiago@gmail.com
//
//  Description   : 
//  1) A fifo é inicializada com todos os espaços vazios
//  2) O avaliador de ativos solicita a leitura do próximo espaço vazio, então é realizada uma leitura da fifo
//  3) Quando um nó é desativado, sua posição é liberada e armazenada na fifo
//  Problema 1: Quando um nó é desativado, e o mesmo possuí diversos vizinhos que serão ativados, caso a fifo seja do tamanho de NA 
//  não existirá espaço para armazenar os novos nós ativos.
//  Problema 2: Ao se aumentar o tamanho da fifo para resolver a situção do problema 1, se gerou outro problema. Acredito que está escrevendo 
//  mais do que existem NA disponiveis, ao aumentar a quantidade de NA o problema é resolvido.
//  Solução: O lVV foi alterado para realizar no inicio das suas operações a desativação de todos os nós aprovados.
//==================================================================================================
module gerenciador_ativos
        #(
            parameter NUM_NA = 8,
            parameter ADDR_WIDTH = 5,
            parameter DISTANCIA_WIDTH = 5,
            parameter CUSTO_WIDTH = 4,
            parameter NUM_READ_PORTS = 8,
            parameter NUM_EA = 8
        )
        (/*autoport*/
            input clk,
            input rst_n,
            input desativar_in,
            input atualizar_in,
            input top_atualizar_fonte_in,
            input [ADDR_WIDTH-1:0] top_endereco_fonte_in,
            // Interface com o LVV
            input [NUM_READ_PORTS-1:0] vizinho_valido_in,
            input [ADDR_WIDTH*NUM_EA-1:0] endereco_in,
            input [ADDR_WIDTH-1:0] anterior_in,
            input [CUSTO_WIDTH*NUM_EA-1:0] menor_vizinho_in,
            input [DISTANCIA_WIDTH*NUM_EA-1:0] distancia_in,
            input [ADDR_WIDTH*NUM_NA-1:0] na_endereco_in,
            input [NUM_NA-1:0] na_ativo_in,
            output ga_atualizar_ready_out,
            
            // Interface com os NAs
            output reg ga_desativar_out,
            output reg ga_atualizar_out,
            output reg [ADDR_WIDTH-1:0] ga_anterior_out,
            output reg [NUM_NA-1:0] ga_habilitar_out,
            output [ADDR_WIDTH*NUM_NA-1:0] ga_endereco_out,
            output [CUSTO_WIDTH*NUM_NA-1:0] ga_menor_vizinho_out,
            output [DISTANCIA_WIDTH*NUM_NA-1:0] ga_distancia_out,

            output ga_ocupado_o
        );

//*******************************************************
//Internal
//*******************************************************
//Local Parameters
localparam COUNT_WIDTH = 3;
localparam COUNT_VAZIO_WIDTH = $clog2(NUM_EA);
localparam COUNT_NA_WIDTH = $clog2(NUM_NA);
genvar i, j;
integer w, k;

//Wires
wire [ADDR_WIDTH-1:0] na_endereco_2d [0:NUM_NA-1];
wire [NUM_NA-1:0] hit [0:NUM_EA-1];
wire [NUM_EA-1:0] tem_hit;
wire vazios_analisados;
//Registers
//*******************************************************
// Convertendo sinais
//*******************************************************
// entrada para 2d
wire [ADDR_WIDTH-1:0] endereco_2d [0:NUM_EA-1];
wire [CUSTO_WIDTH-1:0] menor_vizinho_2d [0:NUM_EA-1];
wire [DISTANCIA_WIDTH-1:0] distancia_2d [0:NUM_EA-1];
generate
    for (i = 0; i < NUM_EA; i = i + 1) begin:convert_dimension_in
        assign endereco_2d[i] = endereco_in[ADDR_WIDTH*i+ADDR_WIDTH-1:ADDR_WIDTH*i];
        assign menor_vizinho_2d[i] = menor_vizinho_in[CUSTO_WIDTH*i+CUSTO_WIDTH-1:CUSTO_WIDTH*i];
        assign distancia_2d[i] = distancia_in[DISTANCIA_WIDTH*i+DISTANCIA_WIDTH-1:DISTANCIA_WIDTH*i];
    end
endgenerate

// saida para 1d
reg [ADDR_WIDTH-1:0] ga_endereco_2d [0:NUM_NA-1];
reg [CUSTO_WIDTH-1:0] ga_menor_vizinho_2d [0:NUM_NA-1];
reg [DISTANCIA_WIDTH-1:0] ga_distancia_2d [0:NUM_NA-1];

generate
    for (i = 0; i < NUM_NA; i = i + 1) begin:convert_dimension_out
        assign ga_endereco_out[ADDR_WIDTH*i+ADDR_WIDTH-1:ADDR_WIDTH*i] = ga_endereco_2d[i];
        assign ga_menor_vizinho_out[CUSTO_WIDTH*i+CUSTO_WIDTH-1:CUSTO_WIDTH*i] = ga_menor_vizinho_2d[i];
        assign ga_distancia_out[DISTANCIA_WIDTH*i+DISTANCIA_WIDTH-1:DISTANCIA_WIDTH*i] = ga_distancia_2d[i];
    end
endgenerate
//*******************************************************
//Identificando NA vazios
//*******************************************************
reg [COUNT_NA_WIDTH-1:0] proximo_vazio [0:NUM_EA-1];
reg [NUM_EA-1:0] proximo_vazio_valido;
reg [COUNT_NA_WIDTH-1:0] count_vazios;

assign vazios_analisados = count_vazios == NUM_EA - 1;

// TODO: Tentar melhorar essa lógica
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        count_vazios <= 0;
        for (w = 0; w < NUM_EA; w = w + 1) begin
            proximo_vazio[w] <= 0;
            proximo_vazio_valido[w] <= 0;
        end
    end
    else begin
        // Resetando
        if (ga_desativar_out || ga_atualizar_out) begin
            count_vazios <= 0;
            proximo_vazio_valido <= 0;
            for (k = 0; k < NUM_EA; k = k + 1) begin
                proximo_vazio[k] <= 0;
            end
        end
        else begin
            if (!vazios_analisados)
                count_vazios <= count_vazios + 1;
            for (w = 0; w < NUM_NA; w = w + 1) begin
                // Ativando o primeiro
                if (na_ativo_in[w]==0) begin
                    proximo_vazio[0] <= w;
                    proximo_vazio_valido[0] <= 1;
                end

                for (k = 1; k < NUM_EA; k = k + 1) begin
                    if (na_ativo_in[w]==0 && proximo_vazio_valido[k-1]==1 && w < proximo_vazio[k-1]) begin
                        proximo_vazio[k] <= w;
                        proximo_vazio_valido[k] <= 1;
                    end
                end
            end
        end
    end
end

//*******************************************************
//Sinais de controle
//*******************************************************
assign ga_ocupado_o = (desativar_in || atualizar_in || ga_desativar_out || ga_atualizar_out) || !vazios_analisados;

//*******************************************************
//General Purpose Signals
// Verificando se o endereço se encontra armazenado e ativo, só pode existir um endereço por nó.
// O hit verifica se o endereço recebido está armazenado em um nó ativo.
//*******************************************************
generate
    for (i = 0; i < NUM_NA; i = i + 1)begin
        assign na_endereco_2d[i] = na_endereco_in[ADDR_WIDTH*i+ADDR_WIDTH-1:ADDR_WIDTH*i];
        for (j = 0; j < NUM_EA; j = j + 1)begin
            assign hit[j][i] = ((na_endereco_2d[i] == endereco_2d[j]) && na_ativo_in[i]) ? 1'b1: 1'b0;
        end
    end
endgenerate

generate
    for (j = 0; j < NUM_EA; j = j + 1)begin
        assign tem_hit[j] = |hit[j];
    end
endgenerate
//*******************************************************
//Outputs
// TODO: Verificar se é possível não ter que registrar todos os sinais, apenas os de controle.
//*******************************************************
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        ga_habilitar_out <= {NUM_NA{1'b0}};
    end
    else begin
        ga_habilitar_out <= {NUM_NA{1'b0}};
        if (top_atualizar_fonte_in) 
            ga_habilitar_out <= {{(NUM_NA-1){1'b0}}, 1'b1};
        else begin
            if (atualizar_in)
                for (k = 0; k < NUM_EA; k = k + 1) begin
                    if (vizinho_valido_in[k]) begin
                        if (tem_hit[k])
                            for (w = 0; w < NUM_NA; w = w + 1) begin
                                if (hit[k][w]   )
                                    ga_habilitar_out[w] <= 1'b1;
                            end
                            // ga_habilitar_out[k] <= ga_habilitar_out | hit[k];
                        else begin
                            if (proximo_vazio_valido[k])
                                ga_habilitar_out[proximo_vazio[k]] <= 1'b1;
                        end
                    end
                end
        end
    end
end

assign ga_atualizar_ready_out = ga_atualizar_out;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (k = 1; k < NUM_NA; k = k + 1) begin
            ga_endereco_2d[k] <= {ADDR_WIDTH{1'b0}};
            ga_menor_vizinho_2d[k] <= {CUSTO_WIDTH{1'b0}};
            ga_distancia_2d[k] <= {DISTANCIA_WIDTH{1'b0}};
        end
        ga_desativar_out <= 1'b0;
        ga_atualizar_out <= 1'b0;
        ga_anterior_out <= {ADDR_WIDTH{1'b0}};
    end
    else begin
        if (top_atualizar_fonte_in) begin
            ga_endereco_2d[0] <= top_endereco_fonte_in;
            ga_distancia_2d[0] <= {DISTANCIA_WIDTH{1'b0}};
            ga_menor_vizinho_2d[0] <= {CUSTO_WIDTH{1'b0}};

            ga_atualizar_out <= 1'b1;
            ga_desativar_out <= 1'b0;
            ga_anterior_out <= {ADDR_WIDTH{1'b0}};
        end
        else begin
            ga_desativar_out <= desativar_in;
            ga_atualizar_out <= atualizar_in;
            if (atualizar_in) begin
                for (k = 0; k < NUM_EA; k = k + 1) begin
                    // TODO: Falta corrigir para quando tiver hit
                    if (tem_hit[k]) begin
                        for (w = 0; w < NUM_NA; w = w + 1) begin
                            if (hit[k][w]==1) begin
                                ga_endereco_2d[w] <= endereco_2d[k];
                                ga_menor_vizinho_2d[w] <= menor_vizinho_2d[k];
                                ga_distancia_2d[w] <= distancia_2d[k];
                            end
                        end
                    end
                    else begin
                        ga_endereco_2d[proximo_vazio[k]] <= endereco_2d[k];
                        ga_menor_vizinho_2d[proximo_vazio[k]] <= menor_vizinho_2d[k];
                        ga_distancia_2d[proximo_vazio[k]] <= distancia_2d[k];
                    end
                end

                ga_anterior_out <= anterior_in;
            end
        end
    end
end

endmodule