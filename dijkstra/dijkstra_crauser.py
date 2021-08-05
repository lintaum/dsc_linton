import time
from grafos.random_graph import GraphGen
inf = float('inf')

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
        self.estabelecidos = []
        self.empilhados = {fonte: 0} # armazena o empilhado e a distância
        self.anterior = {}
        self.criterio_out = {}
        self.treshold_out = inf
        self.inicializar()

    def inicializar(self):
        self.anterior[self.fonte] = 0

    def update_tent(self, no_v, no_w):
        """
        calcula a distância entre o nó e a fonte
            tent(w) = min {tent(w), tent(v) + c(v,w)}.
        """
        if no_w in self.empilhados.keys():
            tent_w = self.empilhados[no_w]
        else:
            tent_w = inf

        custo_v_w = self.grafo.get_custo(no_v, no_w)
        tent_v = self.empilhados[no_v]
        tent_vw = custo_v_w + tent_v

        if tent_vw < tent_w:
            self.anterior[no_w] = no_v
            self.empilhados[no_w] = tent_vw

    def get_menor_tent(self):
        """Coletando o menor tent entre os empilhados"""
        menor_tent = None
        for empilhado in self.empilhados:
            if menor_tent:
                if self.empilhados[menor_tent] > self.empilhados[empilhado]:
                    menor_tent = empilhado
            else:
                menor_tent = empilhado
        return menor_tent

    def get_menor_caminho(self):
        """Coletando o menor caminho, lendo do destino até a fonte"""
        menor_caminho = [self.destino]
        no = self.destino
        while no is not self.fonte:
            anterior = self.anterior[no]
            menor_caminho.append(anterior)
            no = anterior

        # Invertendo a ordem da lista
        menor_caminho = menor_caminho[::-1]
        return menor_caminho

    def empilhar_vizinhos(self, no):
        """Empilhando os vizinhos do menor tent e calculando o tent deles"""
        for vizinho in self.grafo.get_relacoes_vizinhos(no):
            no_vizinho = vizinho.nos[1]
            # TODO: talvez isso dê merda
            if no_vizinho not in self.estabelecidos:
                self.update_tent(no, no_vizinho)

    def update_criterio_out(self):
        """o(v) = tent(v) + min{c(v, u) : (v, u) E E} """
        for no in self.empilhados:
            self.criterio_out[no] = self.empilhados[no] + self.grafo.get_menor_vizinho(no).peso

    def update_treshold_out(self):
        """L = min{tent(u) + c(u, z) : u is queued and (u, z) E E} """
        for no in self.empilhados:
            treshold_no = self.empilhados[no] + self.grafo.get_menor_vizinho(no).peso < self.treshold_out
            if treshold_no < self.treshold_out:
                self.treshold_out = treshold_no

    def get_aprovados_out(self):
        """O nó pode ser removido quando a distância dele até a fonte não pode ser menor"""
        self.update_criterio_out()
        aprovados = []
        for no in self.empilhados:
            if self.criterio_out[no] >= self.empilhados[no]:
                aprovados.append(no)
        return aprovados

    def dijkstra(self, debug):
        while len(self.empilhados) > 0:
            """Coletando o menor tent entre os empilhados"""
            menor_tent = self.get_menor_tent()

            """Empilhando os vizinhos do menor tent e calculando o tent deles"""
            self.empilhar_vizinhos(menor_tent)

            """Estabelecendo o nó já visitado e removendo dos empilhados"""
            self.empilhados.pop(menor_tent)
            self.estabelecidos.append(menor_tent)
            # if debug:
            #     print(f"Estabelecido {menor_tent}")

        return self.get_menor_caminho()


def main(debug=False, num_nos=120):
    # Gerando o grafo e plotando
    # num_nos = 120
    graph_gen = GraphGen(max_weigth=10)
    graph_gen.adjacent_lis(nodes=num_nos)
    # graph_gen.plot()

    start = time.time()
    # Calculando o menor caminho
    menor_caminho = DijkstraCrauser(0, num_nos-1, graph_gen.graph).dijkstra(debug)
    end = time.time()
    custo = graph_gen.graph.get_custo_caminho(menor_caminho)
    if debug:
        graph_gen.plot_path(menor_caminho)
        print(f"Tempo Base: {round(end - start,2)}s")
        print(f"Custo do caminho: {custo}")
    # dijkstra(graph_gen.graph)
    return menor_caminho, custo


if __name__ == '__main__':
    main()