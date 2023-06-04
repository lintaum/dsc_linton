//==================================================================================================
//  Filename      : ordenador_escritas.v
//  Created On    : 2023-01-10 08:23:32
//  Last Modified : 2023-02-01 08:07:42
//  Revision      : 
//  Author        : Linton Esteves
//  Company       : UFBA
//  Email         : lintonthiago@gmail.com
//
//  Description   : Seleciona os comandos de atualização gerados pelos expansores dos aprovados e envia 
//  para os avaliadores de ativos
//==================================================================================================
module ordenador_escritas
		#(
			parameter ADDR_WIDTH = 10,
			parameter DISTANCIA_WIDTH = 6,
			parameter NUM_READ_PORTS = 8,
			parameter NUM_EA = 8,
			parameter CUSTO_WIDTH = 4
		)
		(/*autoport*/
			input clk,
			input rst_n,
			// Interface com expansor de aprovados
			output reg [NUM_EA-1:0] ea_atualizar_ready_out,
			input [NUM_EA-1:0] ea_atualizar_in,
            input [NUM_READ_PORTS*NUM_EA-1:0] ea_vizinho_valido_in,
            input [ADDR_WIDTH*NUM_READ_PORTS*NUM_EA-1:0] ea_endereco_in,
            input [CUSTO_WIDTH*NUM_READ_PORTS*NUM_EA-1:0] ea_menor_vizinho_in,
            input [DISTANCIA_WIDTH*NUM_READ_PORTS*NUM_EA-1:0] ea_distancia_in,
            input [ADDR_WIDTH*NUM_EA-1:0] ea_anterior_in,

            // Interface com o Avaliador de ativos
			input aa_atualizar_ready_in,
			input aa_ocupado_in,
            output reg oe_atualizar_out,
            output reg [NUM_READ_PORTS-1:0] oe_vizinho_valido_out,
            output reg [ADDR_WIDTH*NUM_READ_PORTS-1:0] oe_endereco_out,
            output reg [CUSTO_WIDTH*NUM_READ_PORTS-1:0] oe_menor_vizinho_out,
            output reg [DISTANCIA_WIDTH*NUM_READ_PORTS-1:0] oe_distancia_out,
            output reg [ADDR_WIDTH-1:0] oe_anterior_out
		);
//*******************************************************
//Internal
//*******************************************************
//Local Parameters
genvar i;
integer w;
//Wires
wire [NUM_READ_PORTS-1:0] ea_vizinho_valido_2d [0:NUM_EA-1];
wire [ADDR_WIDTH*NUM_READ_PORTS-1:0] ea_endereco_2d [0:NUM_EA-1];
wire [CUSTO_WIDTH*NUM_READ_PORTS-1:0] ea_menor_vizinho_2d [0:NUM_EA-1];
wire [DISTANCIA_WIDTH*NUM_READ_PORTS-1:0] ea_distancia_2d [0:NUM_EA-1];
wire [ADDR_WIDTH-1:0] ea_anterior_2d [0:NUM_EA-1];
//Registers
reg [ADDR_WIDTH-1:0] proximo_no;
reg busy;
//*******************************************************
//General Purpose Signals
//*******************************************************
generate
    for (i = 0; i < NUM_EA; i = i + 1) begin:convert_dimension_in
		assign ea_vizinho_valido_2d[i] = ea_vizinho_valido_in[NUM_READ_PORTS*i+NUM_READ_PORTS-1:NUM_READ_PORTS*i];
		assign ea_endereco_2d[i] = ea_endereco_in[ADDR_WIDTH*NUM_READ_PORTS*i+ADDR_WIDTH*NUM_READ_PORTS-1:ADDR_WIDTH*NUM_READ_PORTS*i];
		assign ea_menor_vizinho_2d[i] = ea_menor_vizinho_in[CUSTO_WIDTH*NUM_READ_PORTS*i+CUSTO_WIDTH*NUM_READ_PORTS-1:CUSTO_WIDTH*NUM_READ_PORTS*i];
		assign ea_distancia_2d[i] = ea_distancia_in[DISTANCIA_WIDTH*NUM_READ_PORTS*i+DISTANCIA_WIDTH*NUM_READ_PORTS-1:DISTANCIA_WIDTH*NUM_READ_PORTS*i];
		assign ea_anterior_2d[i] = ea_anterior_in[ADDR_WIDTH*i+ADDR_WIDTH-1:ADDR_WIDTH*i];
    end
endgenerate
//*******************************************************
//Outputs
//*******************************************************

always @(*) begin
	oe_vizinho_valido_out = ea_vizinho_valido_2d[proximo_no];
	oe_endereco_out = ea_endereco_2d[proximo_no];
	oe_menor_vizinho_out = ea_menor_vizinho_2d[proximo_no];
	oe_distancia_out = ea_distancia_2d[proximo_no];
	oe_anterior_out = ea_anterior_2d[proximo_no];
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        proximo_no <= {ADDR_WIDTH{1'b0}};
    end
    else begin
    	// Bloqueia até finalização da solicitação anterior
    	if (!busy) begin
	        proximo_no <= {ADDR_WIDTH{1'b0}};
	        for (w = 0; w < NUM_EA; w = w +1) begin
	            if (ea_atualizar_in[w]==1)
	                proximo_no <= w;
	        end
        end
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        ea_atualizar_ready_out <= {NUM_EA{1'b0}};
    end
    else begin
    	if (aa_atualizar_ready_in)
    		ea_atualizar_ready_out[proximo_no] <= 1'b1;
    	else
    		ea_atualizar_ready_out[proximo_no] <= 1'b0;
    end
end
// Adicionado um atraso
reg busy_r;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        oe_atualizar_out <= 1'b0;
        busy <= 1'b0;
        busy_r <= 1'b0;
    end
    else begin
    	busy_r <= busy;
    	if (|ea_atualizar_in && !busy && !busy_r && !aa_ocupado_in)
    		oe_atualizar_out <= 1'b1;
    	else 
    		oe_atualizar_out <= 1'b0;

    	if (|ea_atualizar_in && !busy && !busy_r && !aa_ocupado_in)
    		busy <= 1'b1;
    	else if (aa_atualizar_ready_in)
    		busy <= 1'b0;
    end
end

endmodule