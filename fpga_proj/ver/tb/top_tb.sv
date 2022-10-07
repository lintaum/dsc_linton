//==================================================================================================
//  Filename      : top_tb.v
//  Created On    : 2022-08-29 07:33:34
//  Last Modified : 2022-10-07 09:32:04
//  Revision      : 
//  Author        : Linton Esteves
//  Company       : UFBA
//  Email         : lintonthiago@gmail.com
//
//  Description   : 
//
//
//==================================================================================================
`timescale 1ns/1ps

module top_tb
      (/*autoport*/);
//*******************************************************
//Internal
//*******************************************************
//Local Parameters
localparam ADDR_WIDTH = 10;
localparam MAX_VIZINHOS = 8;
localparam DISTANCIA_WIDTH = 6;
localparam CRITERIO_WIDTH = 5;
localparam CUSTO_WIDTH = 3;
localparam DATA_WIDTH = 8;
localparam RELACOES_DATA_WIDTH = MAX_VIZINHOS*(ADDR_WIDTH+CUSTO_WIDTH);
localparam NUM_NA = 8;
//Wires
genvar i;
logic clk;
logic rst_n;
logic [ADDR_WIDTH-1:0] top_addr_fonte_in;
logic [ADDR_WIDTH-1:0] top_addr_destino_in;
logic top_wr_fonte_in;
//*******************************************************
//clock and reset
//*******************************************************
localparam CLK_PERIOD = 5;
localparam RST_PERIOD = 2*CLK_PERIOD;

initial begin
   clk = 0;
   forever begin
      #CLK_PERIOD
      clk = ~clk;
   end
end

initial begin
   rst_n = 1;
   #RST_PERIOD
   rst_n = 0;
   #RST_PERIOD
   rst_n = 1;
end
// Inicializando as memórias
initial begin
  $readmemb("/home/linton/proj_dsc/dsc/mem_relacoes.bin",top_u0.gerenciador_memorias_acesso_externo_u0.mem_relacoes.mem);
  $readmemb("/home/linton/proj_dsc/dsc/mem_obstaculo.bin",top_u0.gerenciador_memorias_acesso_externo_u0.mem_obstaculos.mem);
end

initial begin
  top_addr_fonte_in = 0;
  top_wr_fonte_in = 0;
  top_addr_destino_in = 0;
  @(posedge rst_n);

  repeat(1)@(negedge clk);
  iniciar(2, 12);

end
//*******************************************************
//Tasks
//*******************************************************
task iniciar();
input [ADDR_WIDTH-1:0] fonte;
input [ADDR_WIDTH-1:0] destino;
begin
  top_addr_fonte_in = fonte;
  top_addr_destino_in = destino;
  top_wr_fonte_in = 1;
  @(negedge clk);
  top_wr_fonte_in = 0;
  top_addr_fonte_in = 0;
  top_addr_destino_in = 0;
end
endtask : iniciar

//*******************************************************
//Instantiations
//*******************************************************
top
        #(
            .ADDR_WIDTH(ADDR_WIDTH),
            .DISTANCIA_WIDTH(DISTANCIA_WIDTH),
            .CRITERIO_WIDTH(CRITERIO_WIDTH),
            .CUSTO_WIDTH(CUSTO_WIDTH),
            .DATA_WIDTH(DATA_WIDTH),
            .RELACOES_DATA_WIDTH(RELACOES_DATA_WIDTH),
            .NUM_NA(NUM_NA)
        )
        top_u0
        (/*autoport*/
            .clk(clk),
            .rst_n(rst_n),
            .top_addr_fonte_in(top_addr_fonte_in),
            .top_addr_destino_in(top_addr_destino_in),
            .top_wr_fonte_in(top_wr_fonte_in)
        );
endmodule