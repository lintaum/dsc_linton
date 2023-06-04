//==================================================================================================
//  Filename      : fifo.v
//  Created On    : 2013-12-18 09:43:05
//  Last Modified : 2022-04-29 08:10:46
//  Revision      : 
//  Author        : Linton Esteves
//  Company       : UFBA
//  Email         : linton.thiago@gmail.com
//
//  Description   : 
//
//
//==================================================================================================
`define SIMULATE 1
    
module fifo
       #(
        parameter DATA_WIDTH = 8,
        parameter ADDRESS_WIDTH = 4,
        parameter FIFO_DEPTH = 2**ADDRESS_WIDTH                              
       )
       (/*autoport*/
        //input
        input clk,
        input rst,
        input [DATA_WIDTH-1:0] write_data,
        input write_enable,
        input read_enable,
        //outputs
        output [DATA_WIDTH-1:0] read_data
        
       );

reg [ADDRESS_WIDTH-1:0] read_pointer, 
                        write_pointer;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        read_pointer <= {ADDRESS_WIDTH{1'b0}};
    end
    else begin
        if (read_enable) begin
            read_pointer <= read_pointer + 1'b1;
        end
    end
end

always @(posedge clk or posedge rst) begin
    if (rst) begin
        write_pointer <= {ADDRESS_WIDTH{1'b0}};
    end
    else begin
        if (write_enable) begin
            write_pointer <= write_pointer + 1'b1;
        end
    end
end

`ifdef SIMULATE

reg [DATA_WIDTH-1:0] mem [0:FIFO_DEPTH-1];

integer i;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        for (i = 0; i < FIFO_DEPTH; i = i + 1)begin
            mem[i] <= {DATA_WIDTH{1'b0}};
        end
    end
    else begin
        if (write_enable) begin
            mem[write_pointer] <= write_data;
        end
    end
end

assign read_data = mem[read_pointer]; 

`else

// using generic reg declaration
(* ram_style = "block" *)
(* keep = "yes" *)
reg [DATA_WIDTH-1:0] mem [0:FIFO_DEPTH-1];

integer i;

always @(posedge clk) begin
//    if (rst) begin
//        for (i = 0; i < FIFO_DEPTH; i = i + 1)begin
//            mem[i] <= {DATA_WIDTH{1'b0}};
//        end
//    end
//    else begin
        if (write_enable) begin
            mem[write_pointer] <= write_data;
        end
//    end
end

always @(posedge clk) begin
//		if (rst) read_data <= {DATA_WIDTH{1'b0}};
		read_data <= mem[read_pointer];
end

//// using ram ipcore
//
//  l2ram #(
//    .DATA_WIDTH(DATA_WIDTH),
//    .ADDRESS_WIDTH(ADDRESS_WIDTH),
//    .FIFO_DEPTH(FIFO_DEPTH)
//  )
//  fifo_sram (
//		.clka		(clk),
//		.wea		(write_enable),
//		.addra	(write_pointer),
//		.dina		(write_data),
//		.clkb		(clk),
//		.rstb		(rst),
//		.addrb	(read_pointer),
//		.doutb	(read_data)
//  );

`endif

endmodule