//==================================================================================================
//  Filename      : gerenciador_ativos.v
//  Created On    : 2022-08-26 08:34:19
//  Last Modified : 2023-01-31 10:00:00
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
//  Problema 3: O gerenciador de ativos está demorando para encontrar os nós ativos vazios para armazenar novos nós
//  Ideia 1: Subdividir os NA e fazer com que cada subgrupo fosse direcionado a uma posição dos vazios, mas, isso acabou não funcionando pois, 
//    ocorre uma sobrecarga de algumas posições, travando o sistema por falta de espaços vazios
//  Ideia 2: Dividir a analise dos nós em duas, uma ascendente e outra descendente, melorando a performace em 2x, Problema: como seriam independentes podem existir repetição de endereços vazios
//  Ideia 3: Aumentar o tamanho do vetor com os vazios. Problema: Toda nova análise irá demorar um tempo maior, de acordo com o tamanho do vetor o que pode acabar piorando o tempo.
//  Ideia 4: Criar uma fifo com os endereços vazios. Problema: 
//   
//  Em uma escrita nem todos os vizinhos são válidos, por isso geralmente não se utilizam todos os vazios alocados
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
            input [ADDR_WIDTH*NUM_READ_PORTS-1:0] endereco_in,
            input [ADDR_WIDTH-1:0] anterior_in,
            input [CUSTO_WIDTH*NUM_READ_PORTS-1:0] menor_vizinho_in,
            input [DISTANCIA_WIDTH*NUM_READ_PORTS-1:0] distancia_in,
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
localparam COUNT_VAZIO_WIDTH = $clog2(NUM_READ_PORTS);
localparam COUNT_NA_WIDTH = $clog2(NUM_NA);
genvar i, j;
integer w, k;

//Wires
wire [ADDR_WIDTH-1:0] na_endereco_2d [0:NUM_NA-1];
wire [NUM_READ_PORTS-1:0] tem_hit;
wire tem_um_hit;
wire vazios_analisados;
//Registers
reg [NUM_NA-1:0] hit_reg [0:NUM_READ_PORTS-1];
//*******************************************************

// Convertendo sinais
//*******************************************************
// entrada para 2d
wire [ADDR_WIDTH-1:0] endereco_2d [0:NUM_READ_PORTS-1];
wire [CUSTO_WIDTH-1:0] menor_vizinho_2d [0:NUM_READ_PORTS-1];
wire [DISTANCIA_WIDTH-1:0] distancia_2d [0:NUM_READ_PORTS-1];
generate
    for (i = 0; i < NUM_READ_PORTS; i = i + 1) begin:convert_dimension_in
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
wire [COUNT_NA_WIDTH-1:0] proximo_vazio_wire [0:NUM_READ_PORTS-1];

reg [COUNT_NA_WIDTH-1:0] proximo_vazio [0:NUM_READ_PORTS-1];
reg [COUNT_NA_WIDTH-1:0] proximo_vazio2 [0:NUM_READ_PORTS-1];
reg [NUM_READ_PORTS-1:0] proximo_vazio_valido;
reg [NUM_READ_PORTS-1:0] proximo_vazio_valido2;
reg [COUNT_NA_WIDTH-1:0] count_vazios;
// reg [COUNT_NA_WIDTH-1:0] ultimo_vazio;
reg atualizar_in_reg;
// reg [COUNT_NA_WIDTH-1:0] count_sub_regiao;
assign vazios_analisados = vazios_validos | count_vazios == NUM_READ_PORTS - 1;
assign tem_um_hit = |tem_hit;
assign vazios_validos = &proximo_vazio_valido;

localparam FATOR_DIVISAO = NUM_NA/NUM_READ_PORTS; // = 64/8=8


generate
    for (i = 0; i < NUM_READ_PORTS; i = i + 1)begin
        assign proximo_vazio_wire[i] = vazios_validos ? proximo_vazio[i]: proximo_vazio2[i];
    end
endgenerate

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (w = 0; w < NUM_READ_PORTS; w = w + 1) begin
            proximo_vazio[w] <= 0;
            proximo_vazio_valido[w] <= 1'b0;
        end
    end
    else begin

        if (desativar_in || atualizar_in) begin
            for (k = 0; k < NUM_READ_PORTS; k = k + 1) begin
                proximo_vazio_valido[k] <= 1'b0;
                proximo_vazio[w] <= {COUNT_NA_WIDTH{1'b1}};
                for (w = 0; w < FATOR_DIVISAO; w = w + 1) begin
                    if (na_ativo_in[k*FATOR_DIVISAO + w] == 0) begin
                        proximo_vazio[k] <= k*FATOR_DIVISAO + w;
                        proximo_vazio_valido[k] <= 1'b1;
                    end
                end
            end
        end
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        count_vazios <= 0;
        for (w = 0; w < NUM_EA; w = w + 1) begin
            proximo_vazio2[w] <= 0;
            proximo_vazio_valido2[w] <= 0;
        end
    end
    else begin
        // Resetando
        if (ga_desativar_out || ga_atualizar_out) begin
            count_vazios <= 0;
            proximo_vazio_valido2 <= 0;
        end
        else begin
            if (!vazios_analisados)
                count_vazios <= count_vazios + 1;
            for (w = 0; w < NUM_NA; w = w + 1) begin
                // Ativando o primeiro
                if (na_ativo_in[w]==0) begin
                    proximo_vazio2[0] <= w;
                    proximo_vazio_valido2[0] <= 1;
                end

                for (k = 1; k < NUM_EA; k = k + 1) begin
                    if (na_ativo_in[w]==0 && proximo_vazio_valido2[k-1]==1 && w < proximo_vazio2[k-1]) begin
                        proximo_vazio2[k] <= w;
                        proximo_vazio_valido2[k] <= 1;
                    end
                end
            end
        end
    end
end

//*******************************************************
//nova fifo vazios
// Ao utilizar um analizador sequencial, quando nem todos os vazios não forem utilizados, pode gerar uma demora na contagem quando existirem muitos NA ocupados de forma espaçada;
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
            if (atualizar_in_reg) begin
                for (k = 0; k < NUM_READ_PORTS; k = k + 1) begin
                    if (vizinho_valido_in[k]) begin
                        if (tem_hit[k])
                            for (w = 0; w < NUM_NA; w = w + 1) begin
                                if (hit_reg[k][w]   )
                                    ga_habilitar_out[w] <= 1'b1;
                            end
                        else begin
                            ga_habilitar_out[proximo_vazio_wire[k]] <= 1'b1;
                        end
                    end
                end
            end
        end
    end
end

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
            ga_atualizar_out <= 1'b0;
            if (atualizar_in_reg) begin
                ga_atualizar_out <= atualizar_in_reg;
                for (k = 0; k < NUM_READ_PORTS; k = k + 1) begin
                    if (tem_hit[k]) begin
                        for (w = 0; w < NUM_NA; w = w + 1) begin
                            if (hit_reg[k][w]==1) begin
                                ga_endereco_2d[w] <= endereco_2d[k];
                                ga_menor_vizinho_2d[w] <= menor_vizinho_2d[k];
                                ga_distancia_2d[w] <= distancia_2d[k];
                            end
                        end
                    end
                    else begin
                        ga_endereco_2d[proximo_vazio_wire[k]] <= endereco_2d[k];
                        ga_menor_vizinho_2d[proximo_vazio_wire[k]] <= menor_vizinho_2d[k];
                        ga_distancia_2d[proximo_vazio_wire[k]] <= distancia_2d[k];
                    end
                end
                ga_anterior_out <= anterior_in;
            end
        end
    end
end
//*******************************************************
//Sinais de controle
//*******************************************************
assign ga_ocupado_o = (desativar_in || atualizar_in || atualizar_in_reg || ga_desativar_out || ga_atualizar_out) || !vazios_analisados;

//*******************************************************
//General Purpose Signals
// Verificando se o endereço se encontra armazenado e ativo, só pode existir um endereço por nó.
// O hit verifica se o endereço recebido está armazenado em um nó ativo.
//*******************************************************
generate
    for (i = 0; i < NUM_NA; i = i + 1)begin
        assign na_endereco_2d[i] = na_endereco_in[ADDR_WIDTH*i+ADDR_WIDTH-1:ADDR_WIDTH*i];
    end
endgenerate


always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        atualizar_in_reg <= 1'b0;
    end
    else begin
        atualizar_in_reg <= atualizar_in;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (k = 0; k < NUM_NA; k = k + 1)begin
            for (w = 0; w < NUM_READ_PORTS; w = w + 1)begin
                hit_reg[w][k] <= 1'b0;
            end
        end
    end
    else begin
        for (k = 0; k < NUM_NA; k = k + 1)begin
            for (w = 0; w < NUM_READ_PORTS; w = w + 1)begin
                if (((na_endereco_2d[k] == endereco_2d[w]) && na_ativo_in[k]))
                    hit_reg[w][k] <= 1'b1;
                else
                    hit_reg[w][k] <= 1'b0;
            end
        end
    end
end

generate
    for (j = 0; j < NUM_READ_PORTS; j = j + 1)begin
        assign tem_hit[j] = |hit_reg[j];
    end
endgenerate
//*******************************************************
//Outputs
// TODO: Verificar se é possível não ter que registrar todos os sinais, apenas os de controle.
//*******************************************************
assign ga_atualizar_ready_out = ga_atualizar_out;

endmodule