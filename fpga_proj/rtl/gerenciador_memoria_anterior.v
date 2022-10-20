//==================================================================================================
//  Filename      : gerenciador_memoria_anterior.v
//  Created On    : 2022-10-04 09:53:21
//  Last Modified : 2022-10-18 14:50:25
//  Revision      : 
//  Author        : Linton Esteves
//  Company       : UFBA
//  Email         : lintonthiago@gmail.com
//
//  Description   : 
//
//
//==================================================================================================
module gerenciador_memoria_anterior
		#(
			parameter ADDR_WIDTH = 10
		)
		(/*autoport*/
			input clk,    // Clock
			input rst_n,  // Asynchronous reset active low
			input [ADDR_WIDTH-1:0] top_fonte_in,
			input [ADDR_WIDTH-1:0] top_destino_in,
			input cme_construir_caminho_in,
			input [ADDR_WIDTH-1:0] write_data_in,
			input write_en_in,
			input [ADDR_WIDTH-1:0] write_addr_in,
			// input read_en_in,
			// input [ADDR_WIDTH-1:0] read_addr_in,
			output reg [ADDR_WIDTH-1:0] read_data_out,
			output reg pronto
		);


//*******************************************************
//Internal
//*******************************************************
//Local Parameters
wire read_en_in;

//Wires
//Registers
reg [ADDR_WIDTH-1:0] read_addr_in;
wire [ADDR_WIDTH-1:0] ram_data;
reg init;

//*******************************************************
//General Purpose Signals
//*******************************************************
assign read_en_in = 1'b1;

always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		read_data_out <= {ADDR_WIDTH{1'b0}};
		read_addr_in <= {ADDR_WIDTH{1'b0}};
		init <= 1'b0;
	end
	else begin
		if (cme_construir_caminho_in) begin
			read_data_out <= read_addr_in;
			if (!init) begin
				init <= 1'b1;
				read_addr_in <= top_destino_in;
			end
			else begin
				read_addr_in <= ram_data;
			end
		end
		else begin
			init <= 1'b0;
		end
	end
end
//*******************************************************
//Outputs
//*******************************************************
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		pronto <= 1'b0;
	end
	else begin
		if (!init)
			pronto <= 1'b0;
		else if (ram_data == top_fonte_in)
			pronto <= 1'b1;
	end
end
//*******************************************************
//Instantiations
//*******************************************************

dual_port_ram 
	#(
		.DATA_WIDTH(ADDR_WIDTH),
		.ADDR_WIDTH(ADDR_WIDTH)
	)
	dual_port_ram_u0
	(
		.clk(clk),
		.rst_n(rst_n),
		.data_i(write_data_in),
		.write_en_i(write_en_in),
		.read_en_i(read_en_in),
		.read_addr_i(read_addr_in),
		.write_addr_i(write_addr_in),
		.data_o(ram_data)
	);

endmodule