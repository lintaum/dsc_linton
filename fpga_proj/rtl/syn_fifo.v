//-----------------------------------------------------
// Design Name : syn_fifo
// File Name   : syn_fifo.v
// Function    : Synchronous (single clock) FIFO
// Coder       : Deepak Kumar Tala
// Adaptado 
//-----------------------------------------------------
module syn_fifo 
#(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8,
    parameter RAM_DEPTH = (1 << ADDR_WIDTH)
  )
  (
    input clk ,
    input rst_n ,
    input rd_en ,
    input wr_en ,
    input [DATA_WIDTH-1:0] data_in ,
    output full ,
    output almost_full ,
    output empty ,
    output almost_empty ,
    output [DATA_WIDTH-1:0] data_out
);    
 
//-----------Internal variables-------------------
reg [ADDR_WIDTH-1:0] wr_pointer;
reg [ADDR_WIDTH-1:0] rd_pointer;
reg [ADDR_WIDTH :0] status_cnt;
wire [DATA_WIDTH-1:0] data_ram ;

//-----------Variable assignments---------------
assign full = (status_cnt == (RAM_DEPTH));
assign empty = (status_cnt == 0);
assign almost_full = (status_cnt == (RAM_DEPTH-1));
assign almost_empty = (status_cnt <= 1);

//-----------Code Start---------------------------
always @ (posedge clk or negedge rst_n)
begin : WRITE_POINTER
  if (!rst_n) begin
    wr_pointer <= 0;
  end else if (wr_en ) begin
    wr_pointer <= wr_pointer + 1'b1;
  end
end

always @ (posedge clk or negedge rst_n)
begin : READ_POINTER
  if (!rst_n) begin
    rd_pointer <= 0;
  end else if (rd_en ) begin
    rd_pointer <= rd_pointer + 1'b1;
  end
end

assign  data_out = data_ram;

// always  @ (posedge clk or negedge rst_n)
// begin : READ_DATA
//   if (!rst_n) begin
//     data_out <= 0;
//   end else if (rd_en ) begin
//     data_out <= data_ram;
//   end
// end

always @ (posedge clk or negedge rst_n)
begin : STATUS_COUNTER
  if (!rst_n) begin
    status_cnt <= 0;
  // Read but no write.
  end else if (rd_en && !(wr_en) 
                && (status_cnt != 0)) begin
    status_cnt <= status_cnt - 1'b1;
  // Write but no read.
  end else if ((wr_en) && !(rd_en) 
               && (status_cnt != RAM_DEPTH)) begin
    status_cnt <= status_cnt + 1'b1;
  end
end 
   
//`ifdef SIM
dual_port_ram_reg 
  #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH)
  )
  mem_u0
  (
    .clk(clk),
    .rst_n(rst_n),
    .data_i(data_in),
    .data_o(data_ram),
    .write_en_i(wr_en),
    .read_en_i(1'b1),
    .read_addr_i(rd_pointer),
    .write_addr_i(wr_pointer)
);  
//`else
// //Colocar memória do FPGA

//ram2port_22bits  
//  #(
//    .DATA_WIDTH(DATA_WIDTH),
//    .ADDR_WIDTH(ADDR_WIDTH)
//  )
//  ram2port_inst (
//  .clock ( clk ),
//  .data ( data_in ),
//  .rdaddress ( rd_pointer ),
//  .wraddress ( wr_pointer ),
//  .wren ( wr_en ),
//  .q ( data_ram )
//  );
//`endif
endmodule
