//==================================================================================================
//  Filename      : gerenciador_estabelecidos.v
//  Created On    : 2022-08-30 10:13:25
//  Last Modified : 2022-11-29 14:00:06
//  Revision      : 
//  Author        : Linton Esteves
//  Company       : UFBA
//  Email         : lintonthiago@gmail.com
//
//  Description   : Armazenar a situação dos nós do grafo quanto ao seu estabelecimento.
//  Essa memória deve ser inicializada com zero.
//
//==================================================================================================
module gerenciador_estabelecidos
		#(
			parameter DATA_WIDTH = 1,
			parameter ADDR_WIDTH = 8,
			parameter NUM_WRITE_PORTS = 1,
      parameter NUM_READ_PORTS = 8
		)
		(/*autoport*/
			input clk,
			input rst_n,
			input soft_reset_n,
			input write_en_in,
			input [ADDR_WIDTH*NUM_WRITE_PORTS-1:0] write_addr_in,
			input [ADDR_WIDTH*NUM_READ_PORTS-1:0] read_addr_in,
			output [DATA_WIDTH*NUM_READ_PORTS-1:0] read_data_out
		);
//*******************************************************
//Internal
//*******************************************************
//Local Parameters
// localparam MEM_SIZE = $pow(ADDR_WIDTH, 2);
localparam MEM_SIZE = 2**ADDR_WIDTH;
integer k;
genvar i;
//Wires
wire [ADDR_WIDTH-1:0] write_addr [0:NUM_WRITE_PORTS-1];
wire [ADDR_WIDTH-1:0] read_addr [0:NUM_READ_PORTS-1];
//Registers
reg [DATA_WIDTH-1:0] mem [0:MEM_SIZE-1];

//*******************************************************
//Converter Dimensão
//*******************************************************
generate
    for (i = 0; i < NUM_WRITE_PORTS; i = i + 1) begin:convert_2d_1d_write
        assign write_addr[i] = write_addr_in[ADDR_WIDTH*i+ADDR_WIDTH-1:ADDR_WIDTH*i];
    end
endgenerate

generate
    for (i = 0; i < NUM_READ_PORTS; i = i + 1) begin:convert_2d_1d_read
        assign read_addr[i] = read_addr_in[ADDR_WIDTH*i+ADDR_WIDTH-1:ADDR_WIDTH*i];
        assign read_data_out[DATA_WIDTH*i+DATA_WIDTH-1:DATA_WIDTH*i] = mem[read_addr[i]];
    end
endgenerate

//*******************************************************
//General Purpose Signals
//*******************************************************

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
       for (k = 0; k < MEM_SIZE; k = k + 1)begin
           mem[k] <= 1'b0;
       end
    end
    else begin
    	if (!soft_reset_n) begin
    		for (k = 0; k < MEM_SIZE; k = k + 1)begin
           		mem[k] <= 1'b0;
       		end	
    	end
        if (write_en_in) begin
            for (k = 0; k < NUM_WRITE_PORTS; k = k + 1) begin
               mem[write_addr[k]] <= 1'b1;
            end
        end
    end
end

//*******************************************************
//Outputs
//*******************************************************

endmodule