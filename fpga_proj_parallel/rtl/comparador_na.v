//==================================================================================================
//  Filename      : comparador_na.v
//  Created On    : 2023-01-19 08:57:42
//  Last Modified : 2023-01-19 14:55:50
//  Revision      : 
//  Author        : Linton Esteves
//  Company       : UFBA
//  Email         : lintonthiago@gmail.com
//
//  Description   : 
//
//
//==================================================================================================
module comparador_na
		#(
			DATA_WIDTH = 8,
			NUM_COMPARADOR = 8
		)
		(/*autoport*/
			input clk,
			input rst_n,
			input iniciar_in,
			input atualizar_in,
			input [DATA_WIDTH*NUM_COMPARADOR-1:0] data_in,
			output reg [DATA_WIDTH-1:0] data_out
		);

integer w;
genvar i;
wire [DATA_WIDTH-1:0] data_in_2d [0: NUM_COMPARADOR-1];
reg [DATA_WIDTH-1:0] data;

generate
    for (i = 0; i < NUM_COMPARADOR; i = i + 1) begin:convert_dimension_in
        assign data_in_2d[i] = data_in[DATA_WIDTH*i+DATA_WIDTH-1:DATA_WIDTH*i];
    end
endgenerate

//*******************************************************
//Outputs
//*******************************************************
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		data_out <= {DATA_WIDTH{1'b1}};
	end
	else begin
		if (iniciar_in)
			data_out <= {DATA_WIDTH{1'b1}};
		else begin
			data_out <= data;
		end
	end
end

always @(*) begin
	data = data_out;
	for (w = 0; w < NUM_COMPARADOR; w = w + 1) begin
    	if (data > data_in_2d[w])
			data = data_in_2d[w];
	end
end

endmodule