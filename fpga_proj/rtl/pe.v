//==================================================================================================
//  Filename      : pe.v
//  Created On    : 2021-08-12 10:59:49
//  Last Modified : 2021-08-12 11:20:09
//  Revision      : 
//  Author        : Linton Esteves
//  Company       : UFBA
//  Email         : linton.thiago@gmail.com
//
//  Description   : 
//
//
//==================================================================================================
module pe
      #(
      	parameter DIST_WIDTH = 8,
      	parameter CUSTO_WIDTH = 8
      )
      (/*autoport*/
         input [DIST_WIDTH-1:0] dist_no_in,
         input [CUSTO_WIDTH-1:0] custo_vizinho_in,
         input [DIST_WIDTH-1:0] dist_vizinho_in,
         output update_out,
         output [DIST_WIDTH-1:0] nova_dist_out 
      );

//*******************************************************
//Outputs
//*******************************************************
assign nova_dist = dist_no + custo_vizinho;

always @(*) begin
	update = 1'b0;
	nova_dist = dist_vizinho_no;
	if (dist_vizinho_no < dist_vizinho) begin
		update = 1'b1;
	end
end

endmodule