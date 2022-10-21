//==================================================================================================
//  Filename      : classificar_ativo.v
//  Created On    : 2022-08-30 09:59:30
//  Last Modified : 2022-10-21 07:45:24
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
			parameter ADDR_WIDTH = 8,
            parameter CRITERIO_WIDTH = 5
		)
		(/*autoport*/
			input clk,
			input rst_n,
			input aa_atualizar_in,
			input [NUM_NA-1:0] na_ativo_in,
			input [NUM_NA*CRITERIO_WIDTH-1:0] na_criterio_in,
			output reg ca_pronto_o,
			output reg [CRITERIO_WIDTH-1:0] ca_criterio_geral_out
			
		);
//*******************************************************
//Internal
//*******************************************************
//Local Parameters
localparam COUNT_WIDTH = $clog2(NUM_NA);
genvar i;
//Wires
wire [CRITERIO_WIDTH-1:0] na_criterio_2d [0:NUM_NA-1];
//Registers
reg [COUNT_WIDTH-1:0] count;
// reg [CRITERIO_WIDTH-1:0] ca_criterio_geral;

//*******************************************************
//General Purpose Signals
//*******************************************************
assign parar_contagem = count == NUM_NA-1;

//Convertendo entrada 1d para 2d
generate
    for (i = 0; i < NUM_NA; i = i + 1) begin:convert_dimension_in
        assign na_criterio_2d[i] = na_criterio_in[CRITERIO_WIDTH*i+CRITERIO_WIDTH-1:CRITERIO_WIDTH*i];
    end
endgenerate

always @(posedge clk or negedge rst_n) begin
   if (!rst_n) begin
      count <= {COUNT_WIDTH{1'b0}};
   end
   else begin
   		if (aa_atualizar_in)
         	count <= 1;
   		else if (parar_contagem) begin
     		count <= {COUNT_WIDTH{1'b0}};
      	end
      	else if (aa_atualizar_in || count != 0)
      		count <= count + 1'b1;
   end
end

always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		ca_pronto_o <= 1'b0;
	end
	else begin
		if (aa_atualizar_in)
			ca_pronto_o <= 1'b0;
		else
			ca_pronto_o <= parar_contagem;
	end
end

//*******************************************************
//Outputs
//*******************************************************
// Otimizar essa lógica para paralelo
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		ca_criterio_geral_out <= {CRITERIO_WIDTH{1'b1}};
	end
	else begin			
		if (aa_atualizar_in)
			if (na_ativo_in[0])
				ca_criterio_geral_out = na_criterio_2d[0];
			else
				ca_criterio_geral_out <= {CRITERIO_WIDTH{1'b1}};
		else if ((ca_criterio_geral_out > na_criterio_2d[count]) & na_ativo_in[count])
			ca_criterio_geral_out <= na_criterio_2d[count];
	end
end

//*******************************************************
//Instantiations
//*******************************************************

endmodule