module buffer
		#(
			DATA_WIDTH = 8
		)
		(/*autoport*/
			input clk,
			input rst_n,
			input write_en_in,
			input [DATA_WIDTH-1:0] data_in,
			output reg [DATA_WIDTH-1:0] data_out
		);

//*******************************************************
//Outputs
//*******************************************************
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		data_out <= 1'b0;
	end
	else begin
		if (write_en_in)
			data_out <= data_in;
	end
end


endmodule