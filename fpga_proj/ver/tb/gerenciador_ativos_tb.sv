//==================================================================================================
//  Filename      : gerenciador_ativos_tb.v
//  Created On    : 2022-08-29 07:33:34
//  Last Modified : 2022-08-30 07:22:40
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

module gerenciador_ativos_tb
      (/*autoport*/);
//*******************************************************
//Internal
//*******************************************************
//Local Parameters
localparam NUM_NA = 8;
localparam ADR_WIDTH = 5;
//Wires
genvar i;
logic [NUM_NA-1:0] habilitar_out;
//Registers
logic desativar_in;
logic atualizar_in;
logic [ADR_WIDTH-1:0] endereco_in;
logic [ADR_WIDTH*NUM_NA-1:0] na_endereco_in;
logic [ADR_WIDTH-1:0] na_endereco_2d [NUM_NA-1:0];
logic [NUM_NA-1:0] na_ativo_in;
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
	desativar_in = 0;
	atualizar_in = 0;
	endereco_in = 0;
	na_endereco_in = 0;
	na_ativo_in = 0;
  @(posedge rst_n);

  // repeat(2)@(negedge clk);
  // atualizar(5);

  repeat(6)@(negedge clk);
  ativar_na(5, 0);
  repeat(6)@(negedge clk);
  ativar_na(7, 1);
  repeat(6)@(negedge clk);
  ativar_na(9, 2);

  repeat(6)@(negedge clk);
  atualizar(9);
  repeat(6)@(negedge clk);
  desativar(5);
  
  
end



//*******************************************************
//Outputs
//*******************************************************
logic posicao;
task ativar_na();
input [ADR_WIDTH-1:0] endereco;
input [NUM_NA-1:0] posicao;
begin
  atualizar(endereco);
  @(posedge |habilitar_out)
  na_ativo_in[posicao] = 1;
  na_endereco_2d[posicao] = endereco;
  @(negedge clk);
end
endtask : ativar_na

task atualizar();
input [ADR_WIDTH-1:0] endereco;
begin
  atualizar_in = 1;
  endereco_in = endereco;
  @(negedge clk);
  atualizar_in = 0;
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

generate
    for (i = 0; i < NUM_NA; i = i + 1) begin:convert_dimension_in
        assign na_endereco_in[ADR_WIDTH*i+ADR_WIDTH-1:ADR_WIDTH*i] = na_endereco_2d[i];
    end
endgenerate

//*******************************************************
//Instantiations
//*******************************************************

 
gerenciador_ativos
	#(
        .NUM_NA(NUM_NA),
        .ADR_WIDTH(ADR_WIDTH)
    )
    gerenciador_ativos_u0
    (/*autoport*/
        .clk(clk),
        .rst_n(rst_n),
        .desativar_in(desativar_in),
        .atualizar_in(atualizar_in),
        .endereco_in(endereco_in),
        .na_endereco_in(na_endereco_in),
        .na_ativo_in(na_ativo_in),
        .habilitar_out(habilitar_out)
    );
endmodule