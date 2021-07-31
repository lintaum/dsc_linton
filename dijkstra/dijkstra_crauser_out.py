import time

from grafos.random_graph import GraphGen
from multiprocessing import Process, Array
inf = float('inf')


def update_tent(no_v, no_w, empilhados, distancia, anterior, grafo):
    """
    calcula a distância entre o nó e a fonte
        tent(w) = min {tent(w), tent(v) + c(v,w)}.
    """
    """Marca o nó como empilhado"""
    empilhados[no_w] = 1
    # Distancia atual
    dist_w = distancia[no_w]
    # Distância a partir do vizinho
    custo_v_w = grafo.get_custo(no_v, no_w)
    dist_v = distancia[no_v]
    dist_vw = custo_v_w + dist_v
    # Se distancia a partir do vizinho é menor, atualiza
    if dist_vw < dist_w:
        anterior[no_w] = no_v
        distancia[no_w] = dist_vw


def empilhar_vizinhos(grafo, no, estabelecidos, empilhados, distancia, anterior):
    """Empilhando os vizinhos do menor tent e calculando o tent deles"""
    for vizinho in grafo.get_relacoes_vizinhos(no):
        no_vizinho = vizinho.nos[1]
        """Se o vizinho já foi estabelecido, já achou o menor caminho então não faz nada"""
        if estabelecidos[no_vizinho] == 0:
            """Se ainda não foi estabelecido, inicializar ou atualizar"""
            update_tent(no, no_vizinho, empilhados, distancia, anterior, grafo)


def remover_no(grafo, no, estabelecidos, empilhados, distancia, anterior):
    """Empilhando os vizinhos do noe calculando o tent deles"""
    empilhar_vizinhos(grafo, no, estabelecidos, empilhados, distancia, anterior)
    """Estabelecendo o nó já visitado e removendo dos empilhados"""
    empilhados[no]=0
    estabelecidos[no]=1
    # print(f"Estabelecido {no}")


class DijkstraCrauser:
    """"
        O menor caminho é formado por todos os menores caminhos do caminho entre a fonte e o destino.
        Dessa forma, para cada nó basta saber qual o nó anterior na direção da fonte para se descobrir,
        o menor caminho.
    """
    def __init__(self, fonte, destino, grafo):
        self.fonte = fonte
        self.destino = destino
        self.grafo = grafo
        self.menor_dist = {}
        self.criterio_out = {}
        self.criterio_in = {}
        # self.treshold_out = inf
        # Memoria Compartilhada
        self.estabelecidos = Array("i", self.grafo.nos)
        self.empilhados = Array("i", self.grafo.nos)
        self.distancia = Array("i", self.grafo.nos)
        self.anterior = Array("i", self.grafo.nos)

        self.estabelecidos = {i:0 for i in range(0, len(self.grafo.nos))}
        self.empilhados = {i:0 for i in range(0, len(self.grafo.nos))}
        self.distancia = {i:100000 for i in range(0, len(self.grafo.nos))}
        self.anterior = {i:0 for i in range(0, len(self.grafo.nos))}
        self.inicializar()

    def inicializar(self):
        self.anterior[self.fonte] = 0
        for no in range(len(self.grafo.nos)):
            self.estabelecidos[no] = 0
            self.empilhados[no] = 0
            self.distancia[no] = 100000000
            self.menor_dist[no] = 100

        self.empilhados[self.fonte] = 1
        self.distancia[self.fonte] = 0
        self.criterio_in[self.fonte] = 0

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

    def update_criterio_out(self):
        """o(v) = tent(v) + min{c(v, u) : (v, u) E E} """
        for no in self.grafo.nos:
            if self.empilhados[no] == 1:
                self.criterio_out[no] = self.distancia[no] + self.grafo.get_menor_vizinho(no).peso

    def update_treshold_out(self):
        """L = min{tent(u) + c(u, z) : u is queued and (u, z) E E} """
        treshold_out = inf
        for no in self.empilhados:
            if self.empilhados[no] == 1:
                treshold_no = self.distancia[no] + self.grafo.get_menor_vizinho(no).peso
                if treshold_no < treshold_out:
                    treshold_out = treshold_no
        return treshold_out

    def get_aprovados_out(self):
        """O nó pode ser removido quando a distância dele até a fonte não pode ser menor"""
        self.update_criterio_out()
        treshold_out = self.update_treshold_out()
        aprovados = []
        for no in self.grafo.nos:
            if self.empilhados[no] == 1:
                # if self.distancia[no] <= self.criterio_out[no]:
                if self.distancia[no] <= treshold_out:
                    aprovados.append(no)
        return aprovados

    def update_criterio_in(self):
        """ i(v) = tent(v) - min{c(u,v) : (u,v) E E}  """
        for no in self.grafo.nos:
            if self.empilhados[no] == 1:
                self.criterio_in[no] = self.distancia[no] - self.grafo.get_menor_vizinho_in(no).peso

    def update_treshold_in(self):
        """M = min {tent(u) : u is queued} """
        self.menor_dist = inf
        for no in self.grafo.nos:
            if self.empilhados[no] == 1:
                if self.distancia[no] < self.menor_dist:
                    self.menor_dist = self.distancia[no]

                # for vizinho in self.grafo.get_relacoes_vizinhos_in(no):
                #     vizinho_no = vizinho.nos[0]
                #     if self.empilhados[vizinho_no] == 1:
                #         # print(self.distancia[vizinho_no])
                #         if self.distancia[vizinho_no] < self.menor_dist[vizinho_no]:
                #             self.menor_dist[vizinho_no] = self.distancia[no]

    def get_aprovados_in(self):
        """i(v) <= M"""
        self.update_criterio_in()
        self.update_treshold_in()
        aprovados = []
        for no in self.grafo.nos:
            if self.empilhados[no] == 1:
                # if self.criterio_in[no] <= self.menor_dist[no]:
                if self.criterio_in[no] <= self.menor_dist:
                    aprovados.append(no)
        return aprovados

    def tem_empilhado(self):
        for no in self.grafo.nos:
            if self.empilhados[no] == 1:
                return True
        return False

    def tem_sem_estabelecer(self):
        for no in self.grafo.nos:
            if self.estabelecidos[no] == 1:
                return True
        return False

    def dijkstra(self, paralelo=True, debug=False):
        count = 0
        while self.tem_empilhado():
            # print(f"Aprovados {self.get_aprovados_out()}")
            count+=1
            """Coletando os nós que podem ser removidos (dist=tent) em paralelo"""
            aprovados_in = self.get_aprovados_in()
            aprovados_out = self.get_aprovados_out()
            aprovados = set(aprovados_in + aprovados_out)
            # aprovados = aprovados_out
            # print(f"\nAprovados IN: {aprovados_in}")
            # print(f"Aprovados OUT: {aprovados_out}")
            if debug:
                print(f"Total nós aprovados: {len(aprovados)} -> NÓS Aprovados : {aprovados}")
                in_dentro = set(aprovados_in).issubset(aprovados_out)
                out_dentro = set(aprovados_out).issubset(aprovados_in)
                # if not in_dentro:
                #     print(f"IN não está dentro do OUT.")
                # if not out_dentro:
                #     print(f"OUT não está dentro do IN.")

            for aprovado in aprovados:
                if paralelo:
                    p = Process(target=remover_no, args=(self.grafo, aprovado, self.estabelecidos, self.empilhados, self.distancia, self.anterior))
                    p.start()
                    p.join()
                else:
                    remover_no(self.grafo, aprovado, self.estabelecidos, self.empilhados, self.distancia, self.anterior)
        if debug:
            print(f"Total de iterações: {count}")
        return self.get_menor_caminho()

def main(num_nos=120, debug=False):
    tempo_objetivo = 425 * 0.000001
    # Gerando o grafo e plotando


    # do stuff
    no_inicio = 0
    no_destino = num_nos-1
    graph_gen = GraphGen(max_weigth=10)
    graph_gen.adjacent_lis(nodes=num_nos)
    # graph_gen.plot()

    # Calculando o menor caminho

    # start = time.time()
    # menor_caminho = DijkstraCrauser(no_inicio, no_destino, graph_gen.graph).dijkstra(paralelo=True)
    # end = time.time()
    # tempo = end - start
    # print(f"Tempo Paralelo: {end - start} | Fator Objetivo: {tempo/tempo_objetivo}")

    start = time.time()
    menor_caminho = DijkstraCrauser(no_inicio, no_destino, graph_gen.graph).dijkstra(paralelo=False, debug=debug)
    end = time.time()
    tempo = end - start
    custo = graph_gen.graph.get_custo_caminho(menor_caminho)
    if debug:
        print(f"Tempo Sequencial: {end - start} | Fator Objetivo: {tempo/tempo_objetivo}")
        print(f"Custo do caminho: {custo}")
        graph_gen.plot_path(menor_caminho)

    return menor_caminho, custo


if __name__ == '__main__':
    from dijkstra_crauser import main as main_crauser
    num_nos = 1024
    debug = True
    if debug:
        caminho1, custo1 = main(num_nos=num_nos, debug=debug,)
        caminho2, custo2 = main_crauser(num_nos=num_nos, debug=debug)

        if custo2 != custo1:
                print(f"Num nós {num_nos}")
                print(f"Custo Out {custo1}")
                print(f"Custo Ref {custo2}")
                print(f"Caminho Out {caminho1}")
                print(f"Caminho Ref {caminho2}")
        else:
            print(f"Passou {num_nos}")
    else:
        for n in range(5,500):
            num_nos = n
            caminho1, custo1 = main(num_nos=num_nos, debug=debug,)
            caminho2, custo2 = main_crauser(num_nos=num_nos, debug=debug)

            if custo2 != custo1:
                print(f"Num nós {num_nos}")
                print(f"Custo Out {custo1}")
                print(f"Custo Ref {custo2}")
                print(f"Caminho Out {caminho1}")
                print(f"Caminho Ref {caminho2}")
            else:
                print(f"Passou {num_nos}")
