//==================================================================================================
//  Filename      : no_ativo_tb.v
//  Created On    : 2022-08-29 07:33:34
//  Last Modified : 2022-08-30 10:17:09
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

module no_ativo_tb
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
logic [CUSTO_WIDTH-1:0] menor_vizinho_in;
logic [DISTANCIA_WIDTH-1:0] distancia_in;
logic [CRITERIO_WIDTH-1:0] ca_criterio_geral_in;
logic [ADR_WIDTH-1:0] endereco_in;
logic [ADR_WIDTH-1:0] anterior_in;
logic atualizar_in;
logic desativar_in;
logic ga_habilitar_in;
logic [CRITERIO_WIDTH-1:0] na_criterio_out;
logic [DISTANCIA_WIDTH-1:0] na_distancia_out;
logic na_atualizar_anterior_out;
logic [ADR_WIDTH-1:0] na_anterior_out;
logic na_aprovado_out;
logic [ADR_WIDTH-1:0] na_endereco_out;
logic na_ativo_out;
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
  menor_vizinho_in = 0;
  distancia_in = 0;
  ca_criterio_geral_in = 0;
  endereco_in = 0;
  anterior_in = 0;
  atualizar_in = 0;
  desativar_in = 0;
  ga_habilitar_in = 0;
  @(posedge rst_n);
  ca_criterio_geral_in = 15;

  repeat(1)@(negedge clk);
  atualizar(1, 2, 5, 20);

  repeat(1)@(negedge clk);
  atualizar(3, 2, 5, 10);

  repeat(1)@(negedge clk);
  atualizar(4, 2, 5, 15);

  repeat(2)@(negedge clk);
  desativar();
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
  ga_habilitar_in = 1;
  anterior_in = anterior;
  endereco_in = endereco;
  menor_vizinho_in = menor_vizinho;
  distancia_in = distancia;
  @(negedge clk);
  atualizar_in = 0;
  ga_habilitar_in = 0;
  anterior_in = 0;
  endereco_in = 0;
  menor_vizinho_in = 0;
  distancia_in = 0;
end
endtask : atualizar

task desativar();
begin
  desativar_in = 1;
  ga_habilitar_in = 1;
  @(negedge clk);
  desativar_in = 0;
  ga_habilitar_in = 0;
end
endtask : desativar

//*******************************************************
//Instantiations
//*******************************************************
no_ativo
    #(
      .ADR_WIDTH(ADR_WIDTH),
      .DISTANCIA_WIDTH(DISTANCIA_WIDTH),
      .CRITERIO_WIDTH(CRITERIO_WIDTH),
      .CUSTO_WIDTH(CUSTO_WIDTH)      
    )
    no_ativo_u0
    (/*autoport*/
      .clk(clk),
      .rst_n(rst_n),
      .menor_vizinho_in(menor_vizinho_in),
      .distancia_in(distancia_in),
      .ca_criterio_geral_in(ca_criterio_geral_in),
      .endereco_in(endereco_in),
      .anterior_in(anterior_in),
      .atualizar_in(atualizar_in),
      .desativar_in(desativar_in),
      .ga_habilitar_in(ga_habilitar_in),
      .na_criterio_out(na_criterio_out),
      .na_distancia_out(na_distancia_out),
      .na_atualizar_anterior_out(na_atualizar_anterior_out),
      .na_anterior_out(na_anterior_out),
      .na_aprovado_out(na_aprovado_out),
      .na_endereco_out(na_endereco_out),
      .na_ativo_out(na_ativo_out)
    );
endmodule