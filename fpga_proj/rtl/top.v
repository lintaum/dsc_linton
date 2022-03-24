//==================================================================================================
//  Filename      : top.v
//  Created On    : 2021-08-12 09:57:47
//  Last Modified : 2021-08-12 10:59:25
//  Revision      : 
//  Author        : Linton Esteves
//  Company       : UFBA
//  Email         : linton.thiago@gmail.com
//
//  Description   : 
//
//
//==================================================================================================

module top
		#(
			parameter NODE_WIDTH = 8
		)
		(/*autoport*/
			input clk,
			input rst_n,
			input start,
			input [NODE_WIDTH-1:0] fonte,
			input [NODE_WIDTH-1:0] destino,
			input [NODE_WIDTH-1:0] obstaculo
		);
//*******************************************************
//Internal
//*******************************************************
//Local Parameters
localparam ST_IDLE = 0,
		   ST_RECEIVE_DATA = 1,
		   ST_INIT = 2,
		   ST_PATH = 3,
		   ST_SEND_DATA = 4;
//Wires

//Registers
reg [2:0] state, next_state;
//*******************************************************
//General Purpose Signals
//*******************************************************
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		state <= ST_INIT;
	end
	else begin
		state <= next_state;
	end
end

always @(*) begin
	next_state = state;
	case (state)
	   ST_INIT: next_state = state;
	   ST_IDLE: next_state = state;
	endcase
end
//*******************************************************
//Outputs
//*******************************************************

//*******************************************************
//Instantiations
//*******************************************************

endmodule