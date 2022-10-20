//==================================================================================================
//  Filename      : top_tb.v
//  Created On    : 2022-08-29 07:33:34
//  Last Modified : 2022-10-20 08:20:34
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

`include "/home/linton/proj_dsc/dsc/defines.vh"


module top_tb
      (/*autoport*/);
//*******************************************************
//Internal
//*******************************************************
//Local Parameters
// localparam NUM_NOS = 64
localparam ADDR_WIDTH = `ADDR_WIDTH;
localparam [`TAMANHO_CAMINHO-1:0][ADDR_WIDTH-1:0] MENOR_CAMINHO = `MENOR_CAMINHO;
localparam CUSTO_CAMINHO = `CUSTO_CAMINHO;
localparam CUSTO_WIDTH = 4;
localparam MAX_VIZINHOS = 8;
localparam DISTANCIA_WIDTH = 10;
localparam CRITERIO_WIDTH = DISTANCIA_WIDTH + 1;
localparam DATA_WIDTH = 8;
localparam UMA_RELACAO_WIDTH = ADDR_WIDTH+CUSTO_WIDTH;
localparam RELACOES_DATA_WIDTH = MAX_VIZINHOS*(UMA_RELACAO_WIDTH);
localparam NUM_NA = `MAX_ATIVOS;
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

reg [ADDR_WIDTH-1:0] menor_caminho_2d [`TAMANHO_CAMINHO-1:0];

generate
    for (i = 0; i < `TAMANHO_CAMINHO; i = i + 1) begin:menor_caminho_convert
      assign menor_caminho_2d[i] = MENOR_CAMINHO[i];
    end
endgenerate

initial begin
  top_addr_fonte_in = 0;
  top_wr_fonte_in = 0;
  top_addr_destino_in = 0;
  @(posedge rst_n);

  repeat(10)@(negedge clk);
  iniciar(`FONTE, `DESTINO);

end

int count;
initial begin
   count = 0;
   verificar();
end

initial begin
   repeat(500000)@(negedge clk);
   $display("Tempo de simulação estourou", );
   $stop();
end

initial begin
   verificar_distancia();
end

//*******************************************************
//Tasks
//*******************************************************
task verificar();
   forever begin
         @(posedge top_u0.clk);
         // if (top_u0.lvv_estabelecidos_write_en && top_u0.lvv_estabelecidos_write_addr == 182) begin
         if (top_u0.lvv_estabelecidos_write_en) begin
            $display("Estabelecido Addr = %0d", top_u0.lvv_estabelecidos_write_addr);
            // $stop();
         end
         if (top_u0.gerenciador_memoria_anterior_u0.pronto) begin
            $display("Terminou de gerar o caminho", );
            $stop();
         end
         
         // Verificando se o caminho está correto
         if (top_u0.gerenciador_memoria_anterior_u0.init) begin
            if (top_u0.gerenciador_memoria_anterior_u0.read_addr_in!=menor_caminho_2d[count])begin
               $warning("Caminho diferente: Simulacao = %0d, Referencia = %0d", top_u0.gerenciador_memoria_anterior_u0.read_addr_in, menor_caminho_2d[count]);
               // $stop();
            end
            else
               $display("Caminho: Simulacao = %0d, Referencia = %0d", top_u0.gerenciador_memoria_anterior_u0.read_addr_in, menor_caminho_2d[count]);
            count = count + 1;
         end
   end
endtask : verificar

task verificar_distancia();
   forever begin
      @(posedge top_u0.gerenciador_memoria_anterior_u0.init);
      if (top_u0.gerenciador_memoria_anterior_u0.init) begin
         for (int count2 = 0; count2 < NUM_NA; count2++) begin
            if (top_u0.avaliador_ativos_u0.na_endereco_2d[count2] == `DESTINO) begin
               if (top_u0.avaliador_ativos_u0.na_distancia_2d[count2] != `CUSTO_CAMINHO) begin
                  $warning("Distância Diferente: Simulação = %0d, Referencia = %0d", top_u0.avaliador_ativos_u0.na_distancia_2d[count2], `CUSTO_CAMINHO);
                  $stop();
               end
               else
                  $display("Distância Aprovada: = %0d", top_u0.avaliador_ativos_u0.na_distancia_2d[count2]);
            end
         end
      end
   end
endtask : verificar_distancia

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
            .MAX_VIZINHOS(MAX_VIZINHOS),
            .ADDR_WIDTH(ADDR_WIDTH),
            .UMA_RELACAO_WIDTH(UMA_RELACAO_WIDTH),
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

