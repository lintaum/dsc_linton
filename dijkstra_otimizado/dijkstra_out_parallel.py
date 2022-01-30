import multiprocessing
import sys
import warnings
import time
from crauser.random_graph import GraphGen
from multiprocessing import Process, Array
from analisador import criar_analise
from fibheap import *
from dijkstra.dijkstra_crauser import main as main_crauser
inf = float('inf')


def update_tent(no_v, no_w, distancia_vizinho, distancia_no, anterior):
    """
    calcula a distância entre o nó e a fonte
        tent(w) = min {tent(w), tent(v) + c(v,w)}.
    """
    """Marca o nó como empilhado"""
    atualizou = False
    # Se distancia a partir do vizinho é menor, atualiza
    if distancia_no < distancia_vizinho:
        atualizou = True
        anterior[no_w] = no_v
        distancia_vizinho = distancia_no

    return atualizou, no_v, distancia_vizinho


def remover_no(no, vizinhos, distancia_vizinhos, anterior_vizinhos, custo_vizinho, return_dict):
    """Empilhando os vizinhos do no e calculando o tent deles"""

    result_vizinho = []
    for no_vizinho in vizinhos:
        """Se ainda não foi estabelecido, inicializar ou atualizar"""
        distancia_v = distancia_vizinhos[no_vizinho]
        distancia_no = custo_vizinho[no_vizinho] + distancia_vizinhos[no]
        atualizou, anterior, distancia = update_tent(no, no_vizinho, distancia_v, distancia_no,  anterior_vizinhos)
        result_vizinho.append([no_vizinho, atualizou, anterior, distancia])

    return_dict[no] = result_vizinho
    return distancia_vizinhos, anterior_vizinhos


def remover_no_aprovado(grafo, aprovado, distancia, anterior, result):
    vizinhos = grafo.get_relacoes_vizinhos(aprovado)
    distancia_vizinhos = {}
    # empilhado_vizinhos = []
    anterior_vizinhos = {}
    custo_vizinho = {}
    vizinhos_validados = []

    for no, vizinho in vizinhos:
        """Se o vizinho já foi estabelecido, já achou o menor caminho então não faz nada"""
        if vizinho not in distancia.keys():
            distancia[vizinho] = inf
        distancia_vizinhos[vizinho] = distancia[vizinho]
        anterior_vizinhos[vizinho] = anterior[vizinho]

        custo_vizinho[vizinho] = grafo.get_custo(no, vizinho)
        vizinhos_validados.append(vizinho)

    distancia_vizinhos[no] = distancia[no]
    remover_no(no, vizinhos_validados, distancia_vizinhos, anterior_vizinhos, custo_vizinho, result)


class DijkstraCrauser:
    """"
        O menor caminho é formado por todos os menores caminhos do caminho entre a fonte e o destino.
        Dessa forma, para cada nó basta saber qual o nó anterior na direção da fonte para se descobrir,
        o menor caminho.
    """
    def __init__(self, fonte, destino, grafo):
        self.total_aprovados_in = []
        self.total_aprovados_out = []
        self.total_empilhados = []

        self.fonte = fonte
        self.destino = destino
        self.grafo = grafo
        self.menor_dist = {}
        self.criterio_out = {}
        # self.treshold_out = inf
        # Memoria Compartilhada
        # self.estabelecidos = Array("i", self.grafo.nos)
        # self.empilhados = Array("i", self.grafo.nos)
        # self.distancia = Array("i", self.grafo.nos)
        # self.anterior = Array("i", self.grafo.nos)

        self.estabelecidos = {i:0 for i in range(0, len(self.grafo.nos))}
        # self.empilhados = {i:0 for i in range(0, len(self.grafo.nos))}
        self.empilhados = []
        self.distancia = {}
        # self.distancia = {i:100000 for i in range(0, len(self.grafo.nos))}
        # self.distancia_pilha = makefheap()
        self.anterior = {i:0 for i in range(0, len(self.grafo.nos))}
        self.inicializar()

    def inicializar(self):
        self.anterior[self.fonte] = 0
        self.empilhados.append(self.fonte)
        for no in range(len(self.grafo.nos)):
            self.estabelecidos[no] = 0
            self.menor_dist[no] = 100

        self.distancia[self.fonte] = 0
        # fheappush(self.distancia_pilha, (0, 0))

    def get_menor_caminho(self):
        """Coletando o menor caminho, lendo do destino até a fonte"""
        menor_caminho = [self.destino]
        no = self.destino
        while no is not self.fonte:
            anterior = self.anterior[no]
            menor_caminho.append(anterior)
            no = anterior
            # print(f"Construindo menor Caminho: {menor_caminho}")
        # Invertendo a ordem da lista
        menor_caminho = menor_caminho[::-1]

        return menor_caminho

    def get_aprovados_out(self):
        """O nó pode ser removido quando a distância dele até a fonte não pode ser menor"""

        aprovados = []
        criterio_out_pilha = makefheap()
        for no in self.empilhados:
            """o(v) = tent(v) + min{c(v, u) : (v, u) E E} - pode ser executado em paralelo"""
            """L = min{tent(u) + c(u, z) : u is queued and (u, z) E E} """
            criterio_out = self.distancia[no] + self.grafo.get_menor_vizinho(no)
            fheappush(criterio_out_pilha, criterio_out)

        treshold_out = criterio_out_pilha.extract_min().key
        for no in self.empilhados:
            if self.distancia[no] <= treshold_out:
                aprovados.append(no)
        return aprovados

    def tem_empilhado(self):
        if len(self.empilhados) > 0:
            return True
        return False

    def tem_sem_estabelecer(self):
        for no in self.grafo.nos:
            if self.estabelecidos[no] == 1:
                return True
        return False

    def dijkstra(self, debug=False):
        count = 0
        manager = multiprocessing.Manager()
        jobs = []

        while self.tem_empilhado():
            # print(f"Aprovados {self.get_aprovados_out()}")
            """Coletando os nós que podem ser removidos (dist=tent) em paralelo"""
            aprovados_out = self.get_aprovados_out()
            aprovados = aprovados_out
            if debug:
                count += 1
                # print(f"Aprovados OUT {len(aprovados_out)}: {aprovados_out}")
                self.total_aprovados_out.append(aprovados_out)
                self.total_empilhados.append(len(self.empilhados))

            result = manager.dict()

            process = []
            for aprovado in aprovados:
                p = multiprocessing.Process(target=remover_no_aprovado, args=(self.grafo, aprovado, self.distancia, self.anterior, result))
                jobs.append(p)
                p.start()
                process.append(p)

            for p in process:
                p.join()

            """Estabelecendo o nó já visitado, removendo dos empilhados e recuperando dados dos buffers"""
            for aprovado in aprovados:
                self.empilhados.remove(aprovado)
                self.estabelecidos[aprovado] = 1
                self.distancia.pop(aprovado)

                for vizinho, atualizou, anterior, distancia in result[aprovado]:
                    if atualizou:
                        if self.estabelecidos[vizinho] == 0:
                            if vizinho not in self.distancia.keys():
                                self.distancia[vizinho] = distancia
                                self.anterior[vizinho] = anterior
                            elif distancia < self.distancia[vizinho]:
                                self.distancia[vizinho] = distancia
                                self.anterior[vizinho] = anterior
                            if vizinho not in self.empilhados:
                                self.empilhados.append(vizinho)
        if debug:
            print(f"\nTotal de iterações: {count}")
            criar_analise(self)
        return self.get_menor_caminho()


def main(num_nos=120, debug=False, grafico=False):
    tempo_objetivo = 425 * 0.001
    # Gerando o grafo e plotando

    # do stuff
    no_inicio = 0
    no_destino = num_nos-1
    graph_gen = GraphGen(max_weigth=10)
    graph_gen.adjacent_lis(nodes=num_nos)
    # graph_gen.plot()

    start = time.time()
    menor_caminho_p = DijkstraCrauser(no_inicio, no_destino, graph_gen.graph).dijkstra(debug=debug)
    end = time.time()
    tempo = end - start
    custo_p = graph_gen.graph.get_custo_caminho(menor_caminho_p)
    if debug:
        print(f"Tempo Paralelo: {round(tempo,2)}s | Fator Objetivo: {round(tempo/tempo_objetivo, 2)}")
    menor_caminho = menor_caminho_p

    custo = graph_gen.graph.get_custo_caminho(menor_caminho)
    if debug:
        print(f"Custo do caminho: {custo}")
    if grafico:
        graph_gen.plot_path(menor_caminho)

    return menor_caminho, custo


if __name__ == '__main__':
    def print_erro():
        print(f"Num nós {num_nos}")
        print(f"Custo Out {custo1}")
        print(f"Custo Ref {custo2}")
        print(f"Caminho Out {caminho1}")
        print(f"Caminho Ref {caminho2}")
    num_nos = 64
    print(f"Num nós {num_nos}")
    debug = True
    grafico = True
    if debug:
        caminho1, custo1 = main(num_nos=num_nos, debug=debug, grafico=grafico)
        caminho2, custo2 = main_crauser(num_nos=num_nos, debug=debug, grafico=False)

        if custo2 != custo1:
            print_erro()
            warnings.warn(f"Foram encontrados erros")
        else:
            print(f"Passou {num_nos}")
    else:
        erro = 0
        for n in range(5, 1024):
            num_nos = n
            caminho1, custo1 = main(num_nos=num_nos, debug=debug,)
            caminho2, custo2 = main_crauser(num_nos=num_nos, debug=debug)

            if custo2 != custo1:
                erro += 1
                print_erro()
                sys.exit()
            else:
                print(f"Passou {num_nos}")

        if erro > 0:
            warnings.warn(f"Foram encontrados {erro} erros")


