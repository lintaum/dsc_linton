//==================================================================================================
//  Filename      : gerenciador_ativos.v
//  Created On    : 2022-08-26 08:34:19
//  Last Modified : 2022-08-30 11:17:28
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
            parameter ADR_WIDTH = 5
        )
        (/*autoport*/
            input clk,
            input rst_n,
            input desativar_in,
            input atualizar_in,
            input [ADR_WIDTH-1:0] endereco_in,
            input [ADR_WIDTH-1:0] anterior_in,
            input [ADR_WIDTH*NUM_NA-1:0] na_endereco_in,
            input [NUM_NA-1:0] na_ativo_in,
            output reg ga_desativar_out,
            output reg ga_atualizar_out,
            output reg [ADR_WIDTH-1:0] ga_anterior_out,
            output reg [ADR_WIDTH-1:0] ga_endereco_out,
            output reg [NUM_NA-1:0] ga_habilitar_out
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

//Wires
genvar i;
wire [ADR_WIDTH-1:0] na_endereco_2d [0:NUM_NA-1];
wire fifo_full;
wire fifo_almost_full;
wire fifo_empty;
wire fifo_almost_empty;
wire [ADR_WIDTH-1:0] fifo_data_out;
wire tem_vazio;
wire [NUM_NA -1:0] hit;
wire [NUM_NA -1:0] hit_fifo;
//Registers
reg [STATE_WIDTH-1:0] state, next_state;
reg [NUM_NA-1:0] count;
reg tem_hit;
reg ler_fifo;
reg escrever_fifo;
reg [NUM_NA-1:0] fifo_data_in;
//*******************************************************
//FSM
//*******************************************************

assign tem_vazio = !fifo_empty;

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
                next_state = ST_DESATIVAR;
            else if (atualizar_in)
                next_state = ST_ATUALIZAR;
        end
        ST_DESATIVAR:
            if (tem_hit)
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

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        ga_desativar_out <= 1'b0;
        ga_atualizar_out <= 1'b0;
    end
    else begin
        if (state == ST_IDLE) begin
            ga_desativar_out <= 1'b0;
            ga_atualizar_out <= 1'b0;
        end
        else if (state == ST_ATUALIZAR)
            ga_atualizar_out <= 1'b1;
        else if (state == ST_DESATIVAR)
            ga_desativar_out <= 1'b1;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        ga_endereco_out <= {ADR_WIDTH{1'b0}};
        ga_anterior_out <= {ADR_WIDTH{1'b0}};
    end
    else begin
        if (state == ST_ENCONTROU)
            ga_endereco_out <= endereco_in;
            ga_anterior_out <= anterior_in;
    end
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
        if (na_ativo_in[count] == 1'b0 && !fifo_almost_full && !fifo_full) begin
            fifo_data_in <= count;
            escrever_fifo <= 1'b1;
        end
        else begin
            escrever_fifo <= 1'b0;
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
        else begin
            ler_fifo <= 1'b0;
        end
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        count = {NUM_NA{1'b0}};
    end
    else begin
        if (!fifo_almost_full && !fifo_full) begin
            if (count == NUM_NA-1)
                count = {NUM_NA{1'b0}};
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
// always @(*) begin
generate
    for (i = 0; i < NUM_NA; i = i + 1)begin
        assign hit[i] = ((na_endereco_2d[i] == endereco_in) && na_ativo_in[i]) ? 1'b1: 1'b0;
        assign hit_fifo[i] = fifo_data_out == i ? 1'b1: 1'b0;
    end
endgenerate
// end

always @(*) begin
    tem_hit = |hit;
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
        ga_habilitar_out <= {NUM_NA{1'b0}};
    end
    else if (state == ST_ENCONTROU) begin
        if (tem_hit)
            ga_habilitar_out <= hit;
        else
            ga_habilitar_out <= hit_fifo;
    end
    else
        ga_habilitar_out <= {NUM_NA{1'b0}};
end

//*******************************************************
//Instantiations
//*******************************************************

syn_fifo 
#(
    .DATA_WIDTH(NUM_NA),
    .ADDR_WIDTH(2)
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