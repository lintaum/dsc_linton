//==================================================================================================
//  Filename      : gerenciador_ativos.v
//  Created On    : 2022-08-26 08:34:19
//  Last Modified : 2022-10-20 15:38:32
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
//==================================================================================================
module gerenciador_ativos
        #(
            parameter NUM_NA = 8,
            parameter ADDR_WIDTH = 5,
            parameter DISTANCIA_WIDTH = 5,
            parameter CUSTO_WIDTH = 4
        )
        (/*autoport*/
            input clk,
            input rst_n,
            input desativar_in,
            input atualizar_in,
            input [ADDR_WIDTH-1:0] endereco_in,
            input [ADDR_WIDTH-1:0] anterior_in,
            input [ADDR_WIDTH*NUM_NA-1:0] na_endereco_in,
            input [NUM_NA-1:0] na_ativo_in,
            input [CUSTO_WIDTH-1:0] menor_vizinho_in,
            input [DISTANCIA_WIDTH-1:0] distancia_in,
            output reg ga_desativar_out,
            output reg ga_atualizar_out,
            output reg [ADDR_WIDTH-1:0] ga_anterior_out,
            output reg [ADDR_WIDTH-1:0] ga_endereco_out,
            output reg [NUM_NA-1:0] ga_habilitar_out,
            output reg [CUSTO_WIDTH-1:0] ga_menor_vizinho_out,
            output reg [DISTANCIA_WIDTH-1:0] ga_distancia_out,
            output ga_ocupado_o,
            // Indica que existem NA disponíveis para receber dados
            output ga_buffers_cheios_o
        );
//*******************************************************
//Internal
//*******************************************************
//Local Parameters
localparam STATE_WIDTH = 3;
localparam ST_IDLE = 0;
localparam ST_DESATIVAR = 1;
localparam ST_ATUALIZAR = 2;
localparam ST_PROCURANDO = 3;
localparam ST_ENCONTROU = 4;
localparam COUNT_WIDTH = 3;
localparam FIDO_DEPTH = NUM_NA;
localparam FIDO_ADD_WIDTH = $clog2(FIDO_DEPTH);
//Wires
genvar i;
wire [ADDR_WIDTH-1:0] na_endereco_2d [0:NUM_NA-1];
wire fifo_full;
wire fifo_almost_full;
wire fifo_empty;
wire fifo_almost_empty;
wire [NUM_NA-1:0] fifo_data_out;
wire tem_vazio;
wire [NUM_NA-1:0] hit;
wire [NUM_NA-1:0] hit_fifo;
wire tem_hit;
//Registers
reg [STATE_WIDTH-1:0] state, next_state;
reg [NUM_NA-1:0] count;
reg ler_fifo;
reg escrever_fifo;
reg [NUM_NA-1:0] fifo_data_in;
reg ga_desativar_reg, ga_atualizar_reg;
//*******************************************************
//Flag signals
//*******************************************************
assign ga_buffers_cheios_o = fifo_empty;
assign ga_ocupado_o = state != ST_IDLE;
assign tem_vazio = !fifo_empty;
assign tem_hit = |hit;

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

// Essa FSM pode ser melhorada
always @(*) begin
    next_state = state;
    case (state)
        ST_IDLE: begin
            if (desativar_in)
                next_state = ST_DESATIVAR;
            else if (atualizar_in)
                next_state = ST_ATUALIZAR;
        end
        ST_DESATIVAR:
            // if (tem_hit)
                next_state = ST_ENCONTROU;
        ST_ATUALIZAR:
            if (tem_hit)
                next_state = ST_ENCONTROU;
            else
                next_state = ST_PROCURANDO;
        ST_PROCURANDO: begin
            if (tem_vazio)
                next_state = ST_ENCONTROU;
        end 
        ST_ENCONTROU: next_state = ST_IDLE;
    endcase
end

//*******************************************************
//Registrando as entradas
//*******************************************************
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        ga_desativar_reg <= 1'b0;
        ga_atualizar_reg <= 1'b0;
        ga_endereco_out <= {ADDR_WIDTH{1'b0}};
        ga_anterior_out <= {ADDR_WIDTH{1'b0}};
        ga_menor_vizinho_out <= {CUSTO_WIDTH{1'b0}};
        ga_distancia_out <= {DISTANCIA_WIDTH{1'b0}};
    end
    else begin
        if (state == ST_IDLE) begin
            ga_endereco_out <= endereco_in;
            ga_anterior_out <= anterior_in;
            ga_desativar_reg <= desativar_in;
            ga_atualizar_reg <= atualizar_in;
            ga_menor_vizinho_out <= menor_vizinho_in;
            ga_distancia_out <= distancia_in;
        end
    end
end
wire achou_desocupado;
assign achou_desocupado = na_ativo_in[count] == 1'b0;
//*******************************************************
//Identificando NA vazios
//*******************************************************
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        fifo_data_in <= 1;
        // escrever_fifo <= 1'b0;
    end
    else begin
        if (init)
            fifo_data_in <= 1 << count;
        else
            fifo_data_in <= hit;
    end
end


always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        escrever_fifo <= 1'b0;
    end
    // if (init && !fifo_almost_full)
    if (init && count < NUM_NA)
        escrever_fifo <= 1'b1;
    else if (ga_desativar_out) begin
        escrever_fifo <= 1'b1;
    end
    else begin
        escrever_fifo <= 1'b0;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        ler_fifo <= 1'b0;
    end
    else begin
        if (state == ST_PROCURANDO) begin
            ler_fifo <= 1'b1;
        end
        else begin
            ler_fifo <= 1'b0;
        end
    end
end

reg liberar_escita_fifo;
reg init;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        init <= 1'b1;
    end
    else begin
        if (count == NUM_NA)
            init <= 1'b0;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        count <= 1;
    end
    else begin
        if (init) begin
            if (count == NUM_NA)
                count <= 1;
            else
                count <= count + 1'b1;
        end
    end
end

//*******************************************************
//General Purpose Signals
// Verificando se o endereço se encontra armazenado e ativo, só pode existir um endereço por nó.
// O hit verifica se o endereço recebido está armazenado em um nó ativo.
// 
// hit_fifo habilita o sinal correspondente ao valor de saída da fifo
// 
// 
//*******************************************************
generate
    for (i = 0; i < NUM_NA; i = i + 1)begin
        assign hit[i] = ((na_endereco_2d[i] == ga_endereco_out) && na_ativo_in[i]) ? 1'b1: 1'b0;
    end
endgenerate
// end

//Convertendo entrada 1d para 2d
generate
    for (i = 0; i < NUM_NA; i = i + 1) begin:convert_dimension_in
        assign na_endereco_2d[i] = na_endereco_in[ADDR_WIDTH*i+ADDR_WIDTH-1:ADDR_WIDTH*i];
    end
endgenerate

//*******************************************************
//Outputs
//*******************************************************
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        ga_habilitar_out <= {NUM_NA{1'b0}};
    end
    else if (state == ST_ENCONTROU) begin
        if (tem_hit)
            ga_habilitar_out <= hit;
        else
            ga_habilitar_out <= fifo_data_out;
    end
    else
        ga_habilitar_out <= {NUM_NA{1'b0}};
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        ga_atualizar_out <= 1'b0;
        ga_desativar_out <= 1'b0;
    end
    else if (state == ST_ENCONTROU) begin
        ga_atualizar_out <= ga_atualizar_reg;
        ga_desativar_out <= ga_desativar_reg;
    end
    else begin
        ga_atualizar_out <= 1'b0;
        ga_desativar_out <= 1'b0;
    end
end

//*******************************************************
//Instantiations
//*******************************************************

syn_fifo 
#(
    .DATA_WIDTH(NUM_NA),
    .ADDR_WIDTH(FIDO_ADD_WIDTH)
  )
fifo_vazios
  (
    .clk(clk),
    .rst_n(rst_n),
    .rd_en(ler_fifo),
    .wr_en(escrever_fifo),
    .data_in(fifo_data_in),
    .full(fifo_full),
    .almost_full(fifo_almost_full),
    .empty(fifo_empty),
    .almost_empty(fifo_almost_empty),
    .data_out(fifo_data_out)
);

endmodule