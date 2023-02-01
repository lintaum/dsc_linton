//==================================================================================================
//  Filename      : gerenciador_leituras.v
//  Created On    : 2022-11-25 11:03:38
//  Last Modified : 2023-02-01 09:17:33
//  Revision      : 
//  Author        : Linton Esteves
//  Company       : UFBA
//  Email         : lintonthiago@gmail.com
//
//  Description   : Gerencia as solicitações de leitura entre os expansores de aprovados e os blocos
//  de memória
//
//==================================================================================================
module gerenciador_leituras
		#(
			NUM_READ_PORTS = 8,
			NUM_EA = 8,
			DATA_WIDH = 32,
			ADDR_WIDTH = 8
		)
		(/*autoport*/
			input clk,
			input rst_n,
			input [NUM_EA-1:0] lvv_read_en_in,
			input [ADDR_WIDTH*NUM_READ_PORTS*NUM_EA-1:0] lvv_read_addr_in,
			output reg [NUM_EA-1:0] ready_out,
			output [DATA_WIDH*NUM_READ_PORTS-1:0] read_data_out,
			//mem_interface
			output reg [ADDR_WIDTH*NUM_READ_PORTS-1:0] read_addr_out,
			input [DATA_WIDH*NUM_READ_PORTS-1:0] mem_read_data_in
		);
//*******************************************************
//Internal
//*******************************************************
//Local Parameters
integer k;
genvar i;
//Wires
wire tem_solicitao;
wire [ADDR_WIDTH*NUM_READ_PORTS-1:0] read_addr [0:NUM_EA-1];
//Registers
reg [ADDR_WIDTH-1:0] proximo_endereco;
//*******************************************************
//Convertendo sinais
//*******************************************************
// entrada para 2d
generate
    for (i = 0; i < NUM_EA; i = i + 1) begin:convert_dimension_in
        assign read_addr[i] = lvv_read_addr_in[ADDR_WIDTH*NUM_READ_PORTS*i+ADDR_WIDTH*NUM_READ_PORTS-1:ADDR_WIDTH*NUM_READ_PORTS*i];
    end
endgenerate
//*******************************************************
//General Purpose Signals
//*******************************************************
assign tem_solicitao = |lvv_read_en_in;

// always @(posedge clk or negedge rst_n) begin
// 	if (!rst_n) begin
// 		proximo_endereco <= {ADDR_WIDTH{1'b0}};
// 	end
// 	else begin
// 		proximo_endereco <= {ADDR_WIDTH{1'b0}};
// 		for (k = 0; k < NUM_EA; k = k + 1) begin
// 		   if (lvv_read_en_in[k] == 1'b1)
// 		   		proximo_endereco <= k;
// 		end
// 	end
// end


always @(*) begin
	proximo_endereco = {ADDR_WIDTH{1'b0}};
	for (k = 0; k < NUM_EA; k = k + 1) begin
	   if (lvv_read_en_in[k] == 1'b1)
	   		proximo_endereco = k;
	end
end
//*******************************************************
//Outputs
//*******************************************************
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		read_addr_out <= {ADDR_WIDTH{1'b0}};
	end
	else begin
		if (tem_solicitao) begin
			read_addr_out <= read_addr[proximo_endereco];
		end
	end
end

assign read_data_out = mem_read_data_in;

always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		ready_out <= {NUM_EA{1'b0}};
	end
	else begin
		ready_out <= {NUM_EA{1'b0}};
		if (tem_solicitao && ready_out[proximo_endereco] != 1'b1 && lvv_read_en_in[proximo_endereco])
			ready_out[proximo_endereco] <= 1'b1;
	end
end

endmodule