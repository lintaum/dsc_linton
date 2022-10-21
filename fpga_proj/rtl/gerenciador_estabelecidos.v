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
			input read_en0_in,
			input read_en1_in,
			input [ADDR_WIDTH-1:0] read_addr0_in,
			input [ADDR_WIDTH-1:0] read_addr1_in,
			output [DATA_WIDTH-1:0] read_data0_out,
			output [DATA_WIDTH-1:0] read_data1_out
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
assign read_data0_out = read_en0_in ? mem[read_addr0_in] : {DATA_WIDTH{1'bz}};
assign read_data1_out = read_en1_in ? mem[read_addr1_in] : {DATA_WIDTH{1'bz}};

//*******************************************************
//Instantiations
//*******************************************************

endmodule