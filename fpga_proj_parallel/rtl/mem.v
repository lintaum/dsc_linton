module mem
		#(
			parameter DATA_WIDTH = 8,
			parameter ADD_WIDTH = 8
		)
		(/*autoport*/
			input clk,
			input rst_n,
			input write_en_in,
			input [DATA_WIDTH-1:0] write_data_in,
			input [ADD_WIDTH-1:0] write_addr_in,
			input read_en_in,
			input [ADD_WIDTH-1:0] read_addr_in,
			output [DATA_WIDTH-1:0] read_data_out
		);
//*******************************************************
//Internal
//*******************************************************
//Local Parameters
localparam MEM_SIZE = $pow(ADD_WIDTH, 2);
//Wires

//Registers

//*******************************************************
//General Purpose Signals
//*******************************************************

//*******************************************************
//Outputs
//*******************************************************

//*******************************************************
//Instantiations
//*******************************************************
`ifdef SIMULATE

	reg [DATA_WIDTH-1:0] mem [0:MEM_SIZE-1];

	integer i;

	always @(posedge clk or posedge rst_n) begin
	    if (!rst) begin
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

	assign read_data_out = read_en_in ? mem[read_addr_in] : {DATA_WIDTH{1'bz}}; 

`else

`endif

endmodule