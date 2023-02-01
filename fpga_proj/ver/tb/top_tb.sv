//==================================================================================================
//    Filename            : top_tb.v
//    Created On        : 2022-08-29 07:33:34
//    Last Modified : 2023-01-16 08:12:25
//    Revision            : 
//    Author                : Linton Esteves
//    Company             : UFBA
//    Email                 : lintonthiago@gmail.com
//
//    Description     : 
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
localparam CUSTO_WIDTH = `CUSTO_WIDTH;
localparam MAX_VIZINHOS = `MAX_VIZINHOS;
localparam DISTANCIA_WIDTH = `DISTANCIA_WIDTH;
localparam CRITERIO_WIDTH = DISTANCIA_WIDTH + 1;
localparam UMA_RELACAO_WIDTH = ADDR_WIDTH+CUSTO_WIDTH;
localparam RELACOES_DATA_WIDTH = MAX_VIZINHOS*(UMA_RELACAO_WIDTH);
localparam NUM_NA = `MAX_ATIVOS;
parameter NUM_EA = 8;
parameter NUM_PORTS = 8;
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

// initial begin
//      verificar_ca();
// end

//*******************************************************
//Tasks
//*******************************************************
// task verificar_ca();
//     forever begin
//         @(posedge top_u0.clk);
//         if (top_u0.avaliador_ativos_u0.classificar_ativo_u0.ca_pronto_o) begin
//             if (top_u0.avaliador_ativos_u0.classificar_ativo_u0.ca_criterio_geral_tmp != top_u0.avaliador_ativos_u0.classificar_ativo_u0.ca_criterio_geral_out) begin
//                 $display("Criterio out diferente", );
//                 $stop();
//             end
//         end
//     end
// endtask : verificar_ca

task verificar();
     forever begin
                 @(posedge top_u0.clk);
                 // if (top_u0.lvv_estabelecidos_write_en && top_u0.lvv_estabelecidos_write_addr == 182) begin
                // if (top_u0.lvv_estabelecidos_write_en) begin
                    // $display("Estabelecido Addr = %0d", top_u0.lvv_estabelecidos_write_addr);
//                        $stop();
                // end
                 if (top_u0.gerenciador_memoria_anterior_u0.pronto_out) begin
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

                 // if (top_u0.avaliador_ativos_u0.gerenciador_ativos_u0.ler_fifo && top_u0.avaliador_ativos_u0.gerenciador_ativos_u0.fifo_empty) begin
                 //    $warning("Leitura na FIFO vazia",);
                 //    $stop();
                 // end

                 // if (top_u0.avaliador_ativos_u0.gerenciador_ativos_u0.fifo_full && top_u0.avaliador_ativos_u0.gerenciador_ativos_u0.vazio_atual_pronto) begin
                 //    $warning("Escrita na FIFO cheia",);
                 //    $stop();
                 // end
     end
endtask : verificar

initial begin
     count = 0;
     mostrar_valores();
end

task mostrar_valores();
    forever begin
        @(posedge top_u0.clk);
        if (top_u0.avaliador_ativos_u0.gerenciador_ativos_u0.atualizar_in) begin
            for (int o = 0; o < NUM_PORTS; o++) begin
                if (top_u0.avaliador_ativos_u0.gerenciador_ativos_u0.vizinho_valido_in[o])
                    $display("Endereço a ser atualizado no AA = %0d, Distância = %0d, Anterior = %0d", top_u0.avaliador_ativos_u0.gerenciador_ativos_u0.endereco_2d[o], top_u0.avaliador_ativos_u0.gerenciador_ativos_u0.distancia_2d[o], top_u0.avaliador_ativos_u0.gerenciador_ativos_u0.anterior_in);
            end
        end

        // if (top_u0.localizador_vizinhos_validos_u0.lvv_estabelecidos_write_en_out) begin
        //     $display("Estabelecido = %0d, Posição no AA = %0d", top_u0.localizador_vizinhos_validos_u0.lvv_estabelecidos_write_addr_out, top_u0.localizador_vizinhos_validos_u0.proximo_aprovado);
        // end

        if (top_u0.localizador_vizinhos_validos_u0.cme_expandir_in) begin
            
            $display("\nCriterio Geral = %0d", top_u0.avaliador_ativos_u0.ca_criterio_geral);
            for (int o = 0; o < NUM_NA; o++) begin
                if (top_u0.avaliador_ativos_u0.aa_aprovado_out[o])
                    $display("Estabelecido = %0d, Distancia = %0d, Criterio = %0d, Posição no AA = %0d", top_u0.avaliador_ativos_u0.na_endereco_2d[o], top_u0.avaliador_ativos_u0.na_distancia_2d[o], top_u0.avaliador_ativos_u0.na_criterio_2d[o], o);
                else if (top_u0.avaliador_ativos_u0.gerenciador_ativos_u0.na_ativo_in[o])
                    $display("No ativo = %0d, Criterio = %0d, Distancia = %0d, Posição no AA = %0d", top_u0.avaliador_ativos_u0.gerenciador_ativos_u0.na_endereco_2d[o], top_u0.avaliador_ativos_u0.na_criterio_2d[o], top_u0.avaliador_ativos_u0.na_distancia_2d[o], o);
            end
            
        end
    end
endtask : mostrar_valores




task verificar_distancia();
     forever begin
            //@(posedge top_u0.gerenciador_memoria_anterior_u0.init);
            @(posedge top_u0.clk);
            if (top_u0.localizador_vizinhos_validos_u0.lvv_estabelecidos_write_en_out && top_u0.localizador_vizinhos_validos_u0.lvv_estabelecidos_write_addr_out == `DESTINO) begin

            // if (top_u0.gerenciador_memoria_anterior_u0.init) begin
                 for (int count2 = 0; count2 < NUM_NA; count2++) begin
                        if (top_u0.avaliador_ativos_u0.na_endereco_2d[count2] == `DESTINO) begin
                             if (top_u0.avaliador_ativos_u0.na_distancia_2d[count2] != `CUSTO_CAMINHO) begin
                                    $warning("Distância Diferente: Simulação = %0d, Referencia = %0d", top_u0.avaliador_ativos_u0.na_distancia_2d[count2], `CUSTO_CAMINHO);
                                    $stop();
                             end
                             else
                                    $display("Distância Aprovada: = %0d", top_u0.avaliador_ativos_u0.na_distancia_2d[count2]);
                                    $stop();
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
                        .RELACOES_DATA_WIDTH(RELACOES_DATA_WIDTH),
                        .NUM_EA(NUM_EA),
                        .NUM_NA(NUM_NA)
                )
                top_u0
                (/*autoport*/
                        .clk(clk),
                        .rst_n(rst_n),
                        .top_addr_fonte_in(top_addr_fonte_in),
                        .top_addr_destino_in(top_addr_destino_in),
                        .obstaculos_wr_data_in(1'b0),
                        .obstaculos_wr_enable_in(1'b0),
                        .obstaculos_wr_addr_in(0),
                        .top_wr_fonte_in(top_wr_fonte_in)
                );
endmodule

