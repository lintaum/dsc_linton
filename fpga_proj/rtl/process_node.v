//==================================================================================================
//  Filename      : process_node.v
//  Created On    : 2021-08-12 11:16:49
//  Last Modified : 2021-08-12 11:22:47
//  Revision      : 
//  Author        : Linton Esteves
//  Company       : UFBA
//  Email         : linton.thiago@gmail.com
//
//  Description   : 
//
//
//==================================================================================================
module process_node
      #(
      	parameter DIST_WIDTH = 8,
      	parameter CUSTO_WIDTH = 8,
      	parameter NUM_VIZINHOS = 8
      )
      (/*autoport*/
         input [DIST_WIDTH-1:0] dist_no_in,
         input [CUSTO_WIDTH*NUM_VIZINHOS-1:0] custo_vizinhos_in,
         input [DIST_WIDTH*NUM_VIZINHOS-1:0] dist_vizinhos_in,
         output [NUM_VIZINHOS-1:0] update_out,
         output [DIST_WIDTH*NUM_VIZINHOS-1:0] nova_dist_out
      );
//*******************************************************
//Internal
//*******************************************************
//Local Parameters

//Wires

wire [CUSTO_WIDTH-1:0] custo_vizinhos_2d [0:NUM_VIZINHOS-1];
wire [CUSTO_WIDTH-1:0] dist_vizinhos_2d [0:NUM_VIZINHOS-1];
wire [CUSTO_WIDTH-1:0] nova_dist_2d [0:NUM_VIZINHOS-1];


//Registers

//*******************************************************
//General Purpose Signals
//*******************************************************
generate
    for (i = 0; i < NUM_VIZINHOS; i = i + 1) begin:convert_dimension_in
        assign custo_vizinhos_2d[i] = custo_vizinhos_in[CUSTO_WIDTH*i+CUSTO_WIDTH-1:CUSTO_WIDTH*i];
        assign dist_vizinhos_2d[i] = dist_vizinhos_in[CUSTO_WIDTH*i+CUSTO_WIDTH-1:CUSTO_WIDTH*i];
    end
endgenerate
//*******************************************************
//Outputs
//*******************************************************
generate
    for (i = 0; i < NUM_VIZINHOS; i = i + 1) begin:convert_dimension_out
        assign nova_dist_out[CUSTO_WIDTH*i+CUSTO_WIDTH-1:CUSTO_WIDTH*i] = nova_dist_2d[i];
    end
endgenerate
//*******************************************************
//Instantiations
//*******************************************************

generate
    for (i = 0; i < NUM_VIZINHOS; i = i + 1) begin:gen_pkt_pe
        pe
        #(
           .DIST_WIDTH(DIST_WIDTH),
           .CUSTO_WIDTH(CUSTO_WIDTH)
        )
        pe_u0  
        (/*autoinst*/
             .dist_no_in(dist_no_in),
             .custo_vizinho_in(custo_vizinhos_2d[i]),
             .dist_vizinho_in(dist_vizinhos_2d[i]),
             .update_out(update_out[i]),
             .nova_dist_out(nova_dist_2d[i]),
        );
    end
endgenerate

endmodule