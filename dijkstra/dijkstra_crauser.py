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
        self.tents = {}
        self.estabelecidos = []
        self.empilhados = [fonte]
        self.anterior = {}
        self.inalcançados = []
        self.inicializar()

    def inicializar(self):
        self.tents[self.fonte] = 0
        self.anterior[self.fonte] = 0
        pass


    def update_tent(self, no_v, no_w):
        """
        calcula a distância entre o nó e a fonte
            tent(w) = min {tent(w), tent(v) + c(v,w)}.
        """
        if no_w in self.tents.keys():
            tent_w = self.tents[no_w]
        else:
            tent_w = inf

        custo_v_w = self.grafo.get_custo(no_v, no_w)
        tent_v = self.tents[no_v]
        tent_vw = custo_v_w + tent_v

        if tent_vw < tent_w:
            self.anterior[no_w] = no_v
            self.tents[no_w] = tent_vw

    def dijkstra(self):
        while len(self.empilhados) > 0:
            """Coletando o menot tent entre os empilhados"""
            menor_tent = None
            for empilhado in self.empilhados:
                if menor_tent:
                    if self.tents[menor_tent] > self.tents[empilhado]:
                        menor_tent = empilhado
                else:
                    menor_tent = empilhado

            """Empilhando os vizinhos do menor e calculando o tent deles"""
            for vizinho in self.grafo.get_relacoes_vizinhos(menor_tent):
                no_vizinho = vizinho.nos[1]
                self.empilhados.append(no_vizinho)
                self.update_tent(menor_tent, no_vizinho)

            """Estabelecendo o nó já visitado e removendo dos empilhados"""
            self.empilhados.remove(menor_tent)
            self.estabelecidos.append(menor_tent)

        menor_caminho = [self.destino]
        no = self.destino
        while no is not self.fonte:
            anterior = self.anterior[no]
            menor_caminho.append(anterior)
            no = anterior

        # Invertendo a ordem da lista
        menor_caminho = menor_caminho[::-1]
        return menor_caminho


if __name__ == '__main__':
    # Gerando o grafo e plotando
    graph_gen = GraphGen(max_weigth=10)
    graph_gen.adjacent_lis(nodes=20)
    graph_gen.plot()

    menor_caminho = DijkstraCrauser(0, 14, graph_gen.graph).dijkstra()
    graph_gen.plot_path(menor_caminho)
    print("Acabou!!")
    # dijkstra(graph_gen.graph)

