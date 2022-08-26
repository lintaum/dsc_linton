//==================================================================================================
//  Filename      : gerenciador_ativos.v
//  Created On    : 2022-08-26 08:34:19
//  Last Modified : 2022-08-26 08:44:40
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
			input [NUM_NA-1:0] na_endereco_in,
			output [NUM_NA-1:0] habilitar_out,

		);
//*******************************************************
//Internal
//*******************************************************
//Local Parameters
localparam ST_IDLE = 0;
localparam ST_PROCURANDO = 1;
//Wires

//Registers
reg [1:0] state, next_state;

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
	case (state)
	   ST_IDLE: next_state = state;
	   ST_PROCURANDO: next_state = state;
	endcase
end
//*******************************************************
//Outputs
//*******************************************************

//*******************************************************
//Instantiations
//*******************************************************

endmodule