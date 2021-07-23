from grafos.random_graph import GraphGen
inf = float('inf')

class DijkstraCrauser:
    def __init__(self, fonte, destino, grafo):
        self.fonte = fonte
        self.destino = destino
        self.grafo = grafo
        self.tents = {}
        self.inicializar()

    def inicializar(self):
        self.tents[self.fonte] = 0
        pass


    def get_tent(self, v):
        """calcula a distância entre o nó e a fontes"""
        pass

    def calc_tent_vizinhos(self, v):
        pass

    def dijkstra(self, grafo, fonte, destino):
        estabelecido = []
        empilhado = [fonte]
        inalcançado = []


if __name__ == '__main__':
    # Gerando o grafo e plotando
    graph_gen = GraphGen(max_weigth=100)
    graph_gen.adjacent_lis(nodes=16)
    graph_gen.plot()

    # dijkstra(graph_gen.graph)

