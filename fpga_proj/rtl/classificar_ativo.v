//==================================================================================================
//  Filename      : classificar_ativo.v
//  Created On    : 2022-08-30 09:59:30
//  Last Modified : 2023-01-31 10:40:01
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
			output [CRITERIO_WIDTH-1:0] ca_criterio_geral_out
			
		);
//*******************************************************
//Internal
//*******************************************************
//Local Parameters
localparam COUNT_WIDTH = $clog2(NUM_NA) + 1;
localparam NUM_COMPARADOR = 10;

genvar i;
integer w;
//Wires
wire [CRITERIO_WIDTH-1:0] na_criterio_2d [0:NUM_NA-1];
wire parar_contagem;
wire [CRITERIO_WIDTH*NUM_COMPARADOR-1:0] comparador_data;
reg [CRITERIO_WIDTH-1:0] comparador_data_2d [0:NUM_COMPARADOR-1];
reg atualizar_comparador;
//Registers
reg [COUNT_WIDTH-1:0] count_comparador;

//*******************************************************
//General Purpose Signals
//*******************************************************
assign parar_contagem = count_comparador >= NUM_NA-1;

//Convertendo entrada 1d para 2d
generate
    for (i = 0; i < NUM_NA; i = i + 1) begin:convert_dimension_in
        assign na_criterio_2d[i] = na_criterio_in[CRITERIO_WIDTH*i+CRITERIO_WIDTH-1:CRITERIO_WIDTH*i];
    end
endgenerate

generate
    for (i = 0; i < NUM_COMPARADOR; i = i + 1) begin:convert_dimension_comparador
        assign comparador_data[CRITERIO_WIDTH*i+CRITERIO_WIDTH-1:CRITERIO_WIDTH*i] = comparador_data_2d[i];
    end
endgenerate

always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		count_comparador <= {COUNT_WIDTH{1'b0}};
		atualizar_comparador <= 1'b0;
	end
	else begin
		atualizar_comparador <= 1'b0;
		if (aa_atualizar_in)
			count_comparador <= {COUNT_WIDTH{1'b0}};
		else if (!parar_contagem) begin
			atualizar_comparador <= 1'b1;
			count_comparador <= count_comparador + NUM_COMPARADOR;
		end
	end
end

always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		for (w = 0; w < NUM_COMPARADOR; w = w + 1) begin
        	comparador_data_2d[w] <= {CRITERIO_WIDTH{1'b1}};
		end
	end
	else begin
		for (w = 0; w < NUM_COMPARADOR; w = w + 1) begin
			if ((count_comparador + w) >= NUM_NA)
            	comparador_data_2d[w] <= {CRITERIO_WIDTH{1'b1}};
            else
            	comparador_data_2d[w] <= na_criterio_2d[count_comparador+w];
		end
	end
end

//*******************************************************
//Outputs
//*******************************************************

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
//Instantiations
//*******************************************************

comparador_na
	#(
		.DATA_WIDTH(CRITERIO_WIDTH),
		.NUM_COMPARADOR(NUM_COMPARADOR)
	)
	comparador_u
	(/*autoport*/
		.clk(clk),
		.rst_n(rst_n),
		.iniciar_in(aa_atualizar_in),
		.atualizar_in(atualizar_comparador),
		.data_in(comparador_data),
		.data_out(ca_criterio_geral_out)
	);



//*******************************************************
//Versão antiga
//*******************************************************
// wire parar_contagem2;
// reg [COUNT_WIDTH-1:0] count;
// reg [CRITERIO_WIDTH-1:0] ca_criterio_geral_tmp;
// reg ca_pronto_tmp;
// assign parar_contagem2 = count == NUM_NA-1;


// always @(posedge clk or negedge rst_n) begin
//    if (!rst_n) begin
//       count <= {COUNT_WIDTH{1'b0}};
//    end
//    else begin
//    		if (aa_atualizar_in)
//          	count <= 1;
//    		else if (parar_contagem2) begin
//      		count <= {COUNT_WIDTH{1'b0}};
//       	end
//       	else if (aa_atualizar_in || count != 0)
//       		count <= count + 1'b1;
//    end
// end

// //*******************************************************
// //Outputs
// //*******************************************************

// // Otimizar essa lógica para paralelo
// always @(posedge clk or negedge rst_n) begin
// 	if (!rst_n) begin
// 		ca_criterio_geral_tmp <= {CRITERIO_WIDTH{1'b1}};
// 	end
// 	else begin			
// 		if (aa_atualizar_in)
// 			if (na_ativo_in[0])
// 				ca_criterio_geral_tmp = na_criterio_2d[0];
// 			else
// 				ca_criterio_geral_tmp <= {CRITERIO_WIDTH{1'b1}};
// 		else if ((ca_criterio_geral_tmp > na_criterio_2d[count]) & na_ativo_in[count])
// 			ca_criterio_geral_tmp <= na_criterio_2d[count];
// 	end
// end

// always @(posedge clk or negedge rst_n) begin
// 	if (!rst_n) begin
// 		ca_pronto_tmp <= 1'b0;
// 	end
// 	else begin
// 		if (aa_atualizar_in)
// 			ca_pronto_tmp <= 1'b0;
// 		else
// 			ca_pronto_tmp <= parar_contagem2;
// 	end
// end
endmodule