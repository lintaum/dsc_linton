from dijkstra_paralel.atualizador_vizinhos import AtualizadorVizinhos
from dijkstra_paralel.avaliador_ativos import Avaliador_ativos
from dijkstra_paralel.formador_caminhos import FormadorCaminho
from dijkstra_paralel.gerenciador_memoria import Memoria, MemoriaInt
from dijkstra_paralel.localizador_vizinhos_validos import LocalizadorVizinhosValidos
from dijkstra_otimizado.dijkstra_out_sequencial import main as main_sequencial
from dijkstra.dijkstra_crauser import main as main_crauser
from crauser.random_graph import GraphGen
import warnings

class DijkstraParallel():
    def __init__(self, num_nos, max_num_vizinhos):
        self.fonte = None
        self.destino = None
        self.num_nos = num_nos
        self.max_num_vizinhos = max_num_vizinhos
        # Criando Blocos
        self.mem_anterior = MemoriaInt(num_nos, 1)
        self.mem_estabelecidos = MemoriaInt(num_nos, 1)
        self.mem_relacoes = Memoria(num_nos, max_num_vizinhos)
        self.mem_obstaculos = Memoria(num_nos, max_num_vizinhos)
        self.avaliador_ativos = Avaliador_ativos()
        self.lvv = LocalizadorVizinhosValidos()
        self.aa = AtualizadorVizinhos()
        self.fc = FormadorCaminho()

    def inicializar_mem(self, grafo):
        for no in grafo.nos:
            relacoes = grafo.get_relacoes_vizinhos(no)
            relacoes = dict(sorted(relacoes.items(), key=lambda item: item[1]))
            relacoes_list = []
            obstaculo_list = []
            for relacao, custo in relacoes.items():
                relacoes_list.append((relacao[1], custo))
                obstaculo_list.append((relacao[1], 0))
            """Inicializando memória de relações"""
            self.mem_relacoes.escrever(no, relacoes_list)
            """Inicializando memória de obstáculos"""
            self.mem_obstaculos.escrever(no, obstaculo_list)
            """Inicializando memória de estabelecidos"""
            self.mem_estabelecidos.escrever(no, 0)
            """Repassando as memórias para o LVV"""
            self.lvv.inicializar_mem(self.mem_relacoes, self.mem_obstaculos, self.mem_estabelecidos)

    def calcular_caminho(self, fonte, destino):
        menor_vizinho = self.lvv.get_menor_vizinho(fonte)
        self.avaliador_ativos.inserir(distancia=0, endereco=fonte, menor_vizinho=menor_vizinho[1])
        while self.avaliador_ativos.tem_ativo():
            aprovados = self.avaliador_ativos.get_aprovados(self.avaliador_ativos.get_criterio_out())
            # print(aprovados)
            buffer = {}
            for aprovado in aprovados:
                relacoes_aprovado = self.lvv.get_relacoes(aprovado)
                distancia_v = self.avaliador_ativos.get_distancia(aprovado)

                for relacao in relacoes_aprovado:
                    endereco_w = relacao[0]
                    custo_vw = relacao[1]
                    distancia_w = self.avaliador_ativos.get_distancia(endereco_w)
                    atualizou, anterior, distancia_vw, endereco_w = self.aa.atualizar(
                                                                                        endereco_w=endereco_w,
                                                                                        custo_vw=custo_vw,
                                                                                        endereco_v=aprovado,
                                                                                        distancia_w=distancia_w,
                                                                                        distancia_v=distancia_v,
                                                                                      )

                    menor_vizinho = self.lvv.get_menor_vizinho(endereco_w)[1]
                    if atualizou:
                        # buffer[aprovado, endereco_w] = [endereco_w, anterior, distancia_vw, menor_vizinho]
                        self.avaliador_ativos.inserir(distancia=distancia_vw, endereco=endereco_w, menor_vizinho=menor_vizinho)
                        self.mem_anterior.escrever(endereco=endereco_w, valor=anterior)

            # for [aprovado, endereco_w], [endereco_w, anterior, distancia_vw, menor_vizinho] in buffer.items():
            #     if self.avaliador_ativos.get_distancia(endereco_w) > distancia_vw and self.mem_estabelecidos.ler(endereco_w)==0:
            #         self.avaliador_ativos.inserir(distancia=distancia_vw, endereco=endereco_w, menor_vizinho=menor_vizinho)
            #         self.mem_anterior.escrever(endereco=endereco_w, valor=anterior)
            # dist(43) = 17
            # dist(50) = 25
            # dist(49) = 20 ?
            # dist(42) = 18

            for aprovado in aprovados:
                self.avaliador_ativos.remover_no(aprovado)
                self.mem_estabelecidos.escrever(endereco=aprovado, valor=1)

            # print("Foi")
        return self.fc.gerar_caminho(fonte, destino, self.mem_anterior)



def main(num_nos=10, debug=False, grafico=False):
    # num_nos = 5
    fonte = 0
    destino = num_nos-1

    top = DijkstraParallel(num_nos=num_nos, max_num_vizinhos=6)
    graph_gen = GraphGen(max_weigth=10)
    graph_gen.adjacent_lis(nodes=num_nos)
    top.inicializar_mem(graph_gen.graph)
    menor_caminho = top.calcular_caminho(fonte=fonte, destino=destino)
    custo = graph_gen.graph.get_custo_caminho(menor_caminho)
    if grafico:
        graph_gen.plot_path(menor_caminho)
    return menor_caminho, custo

if __name__ == '__main__':
    teste = True
    grafico = False
    num_nos = 128
    inicio = 5

    if not teste:
        inicio = num_nos - 1

    for idx in range(inicio, num_nos):
        caminho, custo = main(num_nos=idx, debug=False, grafico=grafico)
        caminho2, custo2 = main_sequencial(num_nos=idx, debug=False, grafico=grafico)

        if custo != custo2:
            warnings.warn(f"Foram encontrados erros: num de nós {idx}")
            print(f"Referência {caminho2, custo2}")
            print(f"Modelo {caminho, custo}")

        else:
            print("Passou!")