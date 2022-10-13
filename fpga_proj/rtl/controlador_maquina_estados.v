//==================================================================================================
//  Filename      : controlador_maquina_estados.v
//  Created On    : 2022-10-06 08:19:57
//  Last Modified : 2022-10-13 10:17:14
//  Revision      : 
//  Author        : Linton Esteves
//  Company       : UFBA
//  Email         : lintonthiago@gmail.com
//
//  Description   : Módulo responsável por controlar a máquina de estados do topo do projeto.
//
//
//==================================================================================================
module controlador_maquina_estados
		(/*autoport*/
			input clk,
			input rst_n,
			input tem_ativo_in,
            input aa_ocupado_in,
            input aa_pronto_in,
            input tem_aprovado_in,
			input iniciar_in,
			input caminho_pronto_in,
			input lido_in,
            input lvv_pronto_in,
			output aguardando_out,
            output caminho_pronto_out,
            output iniciar_out,
            output reg expandir_out,
            output tem_ativo_out,
            output construir_caminho_out
		);
//*******************************************************
//Internal
//*******************************************************
//Local Parameters
localparam STATE_WIDTH = 3;

localparam ST_IDLE = 0,
		   ST_INICIALIZAR = 1,
		   ST_TEM_ATIVO = 2,
           ST_ATUALIZAR_BUFFER = 4,
		   ST_EXPANDIR_ATUALIZAR = 5,
		   ST_ATUALIZAR = 5,
		   ST_CONSTRUIR_CAMINHO = 6,
		   ST_PRONTO = 7;
//Wires

//Registers
reg [STATE_WIDTH-1:0] state, next_state;

//*******************************************************
//General Purpose Signals
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
    if (iniciar_in)
        next_state = ST_INICIALIZAR;
    else begin 
        case (state)
            ST_INICIALIZAR:
                // Insere a fonte no avaliador de ativos
                if (tem_ativo_in && aa_pronto_in)
                    next_state = ST_TEM_ATIVO;
            ST_TEM_ATIVO:
                // Verifica se existem nós ativos a serem analisados
                if (aa_pronto_in)
                    if (tem_ativo_in)
                        next_state = ST_ATUALIZAR_BUFFER;
                    else
                        next_state = ST_CONSTRUIR_CAMINHO;
            ST_ATUALIZAR_BUFFER:
                next_state = ST_EXPANDIR_ATUALIZAR;
            ST_EXPANDIR_ATUALIZAR:
                // Encontra os vizizinhos de um nó e atualiza no AA
                if (lvv_pronto_in)
                    next_state = ST_TEM_ATIVO;
            ST_CONSTRUIR_CAMINHO:
                if (caminho_pronto_in)
                    next_state = ST_PRONTO;
            ST_PRONTO:
    			if (lido_in)
            		next_state = ST_IDLE;
        endcase
    end
end
//*******************************************************
//Outputs
//*******************************************************
assign aguardando_out = state == ST_IDLE;
assign caminho_pronto_out = state == ST_PRONTO;
assign iniciar_out = state == ST_INICIALIZAR;
// assign expandir_out = state == ST_EXPANDIR_ATUALIZAR;
assign construir_caminho_out = state == ST_CONSTRUIR_CAMINHO;
assign tem_ativo_out = state == ST_TEM_ATIVO;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        expandir_out <= 1'b0;
    end
    else begin
        expandir_out = state == ST_EXPANDIR_ATUALIZAR;
    end
end
//*******************************************************
//Instantiations
//*******************************************************

endmodule