//==================================================================================================
//  Filename      : classificar_ativo.v
//  Created On    : 2022-08-30 09:59:30
//  Last Modified : 2022-08-30 10:49:11
//  Revision      : 
//  Author        : Linton Esteves
//  Company       : UFBA
//  Email         : lintonthiago@gmail.com
//
//  Description   : 
//
//
//==================================================================================================
module classificar_ativo
		#(
			parameter NUM_NA = 8,
			parameter ADR_WIDTH = 8,
            parameter CRITERIO_WIDTH = 5
		)
		(/*autoport*/
			input clk,
			input rst_n,
			input [NUM_NA*CRITERIO_WIDTH-1:0] na_criterio_in,
			output reg [CRITERIO_WIDTH-1:0] ca_criterio_geral_out
			
		);
//*******************************************************
//Internal
//*******************************************************
//Local Parameters

//Wires
genvar i;
wire [ADR_WIDTH-1:0] na_criterio_2d [0:NUM_NA-1];
//Registers

//*******************************************************
//General Purpose Signals
//*******************************************************
//Convertendo entrada 1d para 2d
generate
    for (i = 0; i < NUM_NA; i = i + 1) begin:convert_dimension_in
        assign na_criterio_2d[i] = na_criterio_in[CRITERIO_WIDTH*i+CRITERIO_WIDTH-1:CRITERIO_WIDTH*i];
    end
endgenerate

// Refazer isso aqui depois
always @(*) begin
	ca_criterio_geral_out = na_criterio_2d[0];
	// for (i = 1; i < NUM_NA; i = i + 1) begin:identifier
	// 	if (na_criterio_2d < ca_criterio_geral_out)
	// 		ca_criterio_geral_out = na_criterio_2d;
	// end
end
//*******************************************************
//Outputs
//*******************************************************

//*******************************************************
//Instantiations
//*******************************************************

endmodule