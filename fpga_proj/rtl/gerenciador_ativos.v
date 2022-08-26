//==================================================================================================
//  Filename      : gerenciador_ativos.v
//  Created On    : 2022-08-26 08:34:19
//  Last Modified : 2022-08-26 11:23:01
//  Revision      : 
//  Author        : Linton Esteves
//  Company       : UFBA
//  Email         : lintonthiago@gmail.com
//
//  Description   : 
//
//
//==================================================================================================
module gerenciador_ativos
        #(
            parameter NUM_NA = 8,
            parameter ADR_WIDTH = 5,
        )
        (/*autoport*/
            input clk,
            input rst_n,
            input desativar_in,
            input atualizar_in,
            input [ADR_WIDTH-1:0] endereco_in,
            input [ADR_WIDTH*NUM_NA-1:0] na_endereco_in,
            input [NUM_NA-1:0] na_ativo_in,
            output [NUM_NA-1:0] habilitar_out
        );
//*******************************************************
//Internal
//*******************************************************
//Local Parameters
localparam STATE_WIDTH = 3
localparam ST_IDLE = 0;
localparam ST_PROCURANDO = 1;
localparam ST_DESATIVAR = 2;
localparam ST_ATUALIZAR = 3;
localparam ST_ENCONTROU = 4;
localparam COUNT_WIDTH = 3;

//Wires
wire [CUSTO_WIDTH-1:0] na_endereco_2d [0:NUM_VIZINHOS-1];
wire fifo_full;
wire fifo_almost_full;
wire fifo_empty;
wire fifo_almost_empty;
wire [ADR_WIDTH-1:0] fifo_data_out;
//Registers
reg [STATE_WIDTH-1:0] state, next_state;
reg [NUM_VIZINHOS-1:0] hit;
reg [COUNT_WIDTH-1:0] count;
reg tem_hit;
reg tem_vazio;
reg ler_fifo;
reg [ADR_WIDTH-1:0] fifo_data_in;
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
        ST_IDLE: begin
            if (desativar_in)
                next_state = ST_DESATIVAR
            else if (atualizar_in)
                next_state = ST_ATUALIZAR
        end
        ST_DESATIVAR:
            if (tem_hit)
                next_state = ST_ENCONTROU;
        ST_ATUALIZAR:
            if (tem_hit || tem_vazio)
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
//Identificando NA vazios
//*******************************************************
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        fifo_data_in <= {NUM_NA{1'b0}};
        escrever_fifo <= 1'b0;
    end
    else begin
        if (na_ativo_in[count] == 1'b0 && !fifo_almost_full) begin
            fifo_data_in <= count;
            escrever_fifo <= 1'b1;
        end
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
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        count = {COUNT_WIDTH{1'b0}};
    end
    else begin
        if (!fifo_almost_full) begin
            if (count == NUM_NA-1)
                count = {COUNT_WIDTH{1'b0}};
            else
                count = count + 1'b1;
        end
    end
end

//*******************************************************
//General Purpose Signals
//*******************************************************
//Verificando se o endereço se encontra armazenado e ativo, 
//só pode existir um endereço por nó
always @(*) begin
    tem_hit = 1'b0;
    hit = {NUM_NA{1'b0}};
    for (i = 0; i < NUM_NA; i = i + 1)begin
        if ((na_endereco_2d[i] == endereco_in) && na_ativo_in[i]) begin
            tem_hit = 1'b1;
            hit[i] = 1'b1;
        end
    end
end

//Convertendo entrada 1d para 2d
generate
    for (i = 0; i < NUM_NA; i = i + 1) begin:convert_dimension_in
        assign na_endereco_2d[i] = na_endereco_in[ADR_WIDTH*i+ADR_WIDTH-1:ADR_WIDTH*i];
    end
endgenerate

//*******************************************************
//Outputs
//*******************************************************
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        habilitar_out <= {NUM_NA{1'b0}};
    end
    else if (state == ST_ENCONTROU) begin
        habilitar_out <= hit;
    end
end

//*******************************************************
//Instantiations
//*******************************************************

syn_fifo 
#(
    .DATA_WIDTH(NUM_NA),
    .ADDR_WIDTH(2),
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