//==================================================================================================
//  Filename      : gerenciador_estabelecidos.v
//  Created On    : 2022-08-30 10:13:25
//  Last Modified : 2022-11-22 10:11:35
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
			parameter ADDR_WIDTH = 8
		)
		(/*autoport*/
			input clk,
			input rst_n,
			input write_en_in,
			input [DATA_WIDTH-1:0] write_data_in,
			input [ADDR_WIDTH-1:0] write_addr_in,
			input [ADDR_WIDTH-1:0] read_addr0_in,
			input [ADDR_WIDTH-1:0] read_addr1_in,
			input [ADDR_WIDTH-1:0] read_addr2_in,
			input [ADDR_WIDTH-1:0] read_addr3_in,
			input [ADDR_WIDTH-1:0] read_addr4_in,
			input [ADDR_WIDTH-1:0] read_addr5_in,
			input [ADDR_WIDTH-1:0] read_addr6_in,
			input [ADDR_WIDTH-1:0] read_addr7_in,
			input [ADDR_WIDTH-1:0] read_addr8_in,
			output [DATA_WIDTH-1:0] read_data0_out,
			output [DATA_WIDTH-1:0] read_data1_out,
			output [DATA_WIDTH-1:0] read_data2_out,
			output [DATA_WIDTH-1:0] read_data3_out,
			output [DATA_WIDTH-1:0] read_data4_out,
			output [DATA_WIDTH-1:0] read_data5_out,
			output [DATA_WIDTH-1:0] read_data6_out,
			output [DATA_WIDTH-1:0] read_data7_out,
			output [DATA_WIDTH-1:0] read_data8_out
		);
//*******************************************************
//Internal
//*******************************************************
//Local Parameters
// localparam MEM_SIZE = $pow(ADDR_WIDTH, 2);
localparam MEM_SIZE = 2**ADDR_WIDTH;
integer i;
//Wires

//Registers
reg [DATA_WIDTH-1:0] mem [0:MEM_SIZE-1];
//*******************************************************
//General Purpose Signals
//*******************************************************

always @(posedge clk) begin
    if (!rst_n) begin
       for (i = 0; i < MEM_SIZE; i = i + 1)begin
           mem[i] <= {DATA_WIDTH{1'b0}};
       end
    end
    else begin
        if (write_en_in) begin
            mem[write_addr_in] <= write_data_in;
        end
    end
end

//*******************************************************
//Outputs
//*******************************************************
assign read_data0_out = mem[read_addr0_in];
assign read_data1_out = mem[read_addr1_in];
assign read_data2_out = mem[read_addr2_in];
assign read_data3_out = mem[read_addr3_in];
assign read_data4_out = mem[read_addr4_in];
assign read_data5_out = mem[read_addr5_in];
assign read_data6_out = mem[read_addr6_in];
assign read_data7_out = mem[read_addr7_in];
assign read_data8_out = mem[read_addr8_in];

//*******************************************************
//Instantiations
//*******************************************************

endmodule