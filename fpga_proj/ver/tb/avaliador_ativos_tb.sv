//==================================================================================================
//  Filename      : avaliador_ativos_tb.v
//  Created On    : 2022-08-29 07:33:34
//  Last Modified : 2022-08-30 11:02:39
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

module avaliador_ativos_tb
      (/*autoport*/);
//*******************************************************
//Internal
//*******************************************************
//Local Parameters
localparam NUM_NA =  8;
localparam ADR_WIDTH =  5;
localparam DISTANCIA_WIDTH =  5;
localparam CRITERIO_WIDTH =  5;
localparam CUSTO_WIDTH =  4;
//Wires
genvar i;
logic desativar_in;
logic atualizar_in;
logic [ADR_WIDTH-1:0] endereco_in;
logic [CUSTO_WIDTH-1:0] menor_vizinho_in;
logic [DISTANCIA_WIDTH-1:0] distancia_in;
logic [ADR_WIDTH-1:0] anterior_in;
logic clk, rst_n;
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

initial begin
  @(posedge rst_n);
  desativar_in = 0;
  atualizar_in = 0;
  endereco_in = 0;
  menor_vizinho_in = 0;
  distancia_in = 0;
  anterior_in = 0;

  repeat(1)@(negedge clk);
  atualizar(1, 2, 5, 20);

  repeat(1)@(negedge clk);
  atualizar(3, 2, 5, 10);

  repeat(1)@(negedge clk);
  atualizar(4, 2, 5, 15);

  repeat(2)@(negedge clk);
  desativar(2);

end
//*******************************************************
//Tasks
//*******************************************************

task atualizar();
input [ADR_WIDTH-1:0] anterior;
input [ADR_WIDTH-1:0] endereco;
input [CUSTO_WIDTH-1:0] menor_vizinho;
input [DISTANCIA_WIDTH-1:0] distancia;
begin
  atualizar_in = 1;
  anterior_in = anterior;
  endereco_in = endereco;
  menor_vizinho_in = menor_vizinho;
  distancia_in = distancia;
  @(negedge clk);
  atualizar_in = 0;
  anterior_in = 0;
  endereco_in = 0;
  menor_vizinho_in = 0;
  distancia_in = 0;
end
endtask : atualizar

task desativar();
input [ADR_WIDTH-1:0] endereco;
begin
  desativar_in = 1;
  endereco_in = endereco;
  @(negedge clk);
  desativar_in = 0;
end
endtask : desativar


//*******************************************************
//Instantiations
//*******************************************************
avaliador_ativos
    #(
      .NUM_NA(NUM_NA),
      .ADR_WIDTH(ADR_WIDTH),
      .DISTANCIA_WIDTH(DISTANCIA_WIDTH),
      .CRITERIO_WIDTH(CRITERIO_WIDTH),
      .CUSTO_WIDTH(CUSTO_WIDTH)
    )
    avaliador_ativos_u0
    (/*autoport*/
      .clk(clk),
      .rst_n(rst_n),
      .desativar_in(desativar_in),
      .atualizar_in(atualizar_in),
      .endereco_in(endereco_in),
      .menor_vizinho_in(menor_vizinho_in),
      .distancia_in(distancia_in),
      .anterior_in(anterior_in)
    );
endmodule