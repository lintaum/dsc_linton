//==================================================================================================
//  Filename      : gerenciador_ativos_tb.v
//  Created On    : 2022-08-29 07:33:34
//  Last Modified : 2022-08-29 09:33:02
//  Revision      : 
//  Author        : Linton Esteves
//  Company       : UFBA
//  Email         : lintonthiago@gmail.com
//
//  Description   : 
//
//
//==================================================================================================
module gerenciador_ativos_tb
      (/*autoport*/);
//*******************************************************
//Internal
//*******************************************************
//Local Parameters
localparam NUM_NA = 8;
localparam ADR_WIDTH = 5;
//Wires

wire [NUM_NA-1:0] habilitar_out;
//Registers
reg desativar_in;
reg atualizar_in;
reg [ADR_WIDTH-1:0] endereco_in;
reg [ADR_WIDTH*NUM_NA-1:0] na_endereco_in;
reg [NUM_NA-1:0] na_ativo_in;
reg clk, 
    rst_n;
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

  repeat(1)@(negedge clk);
  atualizar(5);

end



//*******************************************************
//Outputs
//*******************************************************
task atualizar();
input [DATA_WIDTH*BUS_SIZE_IN-1:0] endereco;
begin
  atualizar_in = 1;
  endereco_in = data;
  @(negedge clk);
  atualizar_in = 0;
end
endtask : write
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