import random
from math import sqrt
import networkx as nx
import matplotlib.pyplot as plt
from crauser.grafo import Grafo

class GraphGen:
    def __init__(self, max_weigth):
        self.graph = Grafo()
        self.max_weigth = max_weigth
        self.nodes = None



    def adjacent_lis(self, nodes):
        L = int(sqrt(nodes))
        perfect_sqrt = (nodes % L) == 0
        # graph = []

        for n in range(nodes):
            pos = n % L
            last = nodes - n
            is_top = n < L
            is_rigth = pos == L - 1
            is_left = pos == 0
            is_botton = last <= L

            # norte
            if not (is_top):
                random.seed(n)
                self.graph.add_relacao(n, n-L, random.randint(1, self.max_weigth))

            # sul
            if not (is_botton):
                random.seed(n+L)
                self.graph.add_relacao(n, n+L, random.randint(1, self.max_weigth))

            # leste
            if not is_rigth and (n < nodes-1):
                random.seed(n+1)
                self.graph.add_relacao(n, n+1, random.randint(1, self.max_weigth))

            # oeste
            if not is_left:
                random.seed(n)
                self.graph.add_relacao(n, n-1, random.randint(1, self.max_weigth))

            # suldeste
            if not (is_rigth or is_botton) and (n+L+1 < nodes):
                random.seed(n+1+1)
                self.graph.add_relacao(n, n+L+1, random.randint(1, self.max_weigth))

            # nordeste
            if not (is_top or is_rigth):
                random.seed(n-L+1+1)
                self.graph.add_relacao(n, (n-L)+1, random.randint(1, self.max_weigth))

            # suldoeste
            if not (is_botton or is_left):
                random.seed(n+1)
                self.graph.add_relacao(n, (n+L)-1, random.randint(1, self.max_weigth))

            # noroeste
            if not (is_top or is_left):
                random.seed((n-L+1))
                self.graph.add_relacao(n, (n-L)-1, random.randint(1, self.max_weigth))

            self.graph.add_no(n)
        # self.graph = graph
        self.nodes = nodes
        return self.graph

    def plot(self):

        # Build your graph
        G = nx.DiGraph()
        L = int(sqrt(self.nodes))
        perfect_sqrt = (self.nodes % L) == 0

        add_one = (self.nodes % 2 is not 0) and (not perfect_sqrt)

        for node in range(self.nodes):
            posx = node % L
            posy = L-1-int(node / L)
            # posy = int(node / L)
            G.add_node(node, pos=(posx,posy))
            # print(f'Node {node} ({posx}, {posy})')

        for v in G.nodes:
            G.nodes[v]['state']= v
        print('\n')
        for nos, custo in self.graph.get_relacoes().items():
            G.add_edge(nos[0], nos[1], weight=custo)


        pos=nx.get_node_attributes(G, 'pos')
        nx.draw(G, pos)
        node_labels = nx.get_node_attributes(G,'state')
        nx.draw_networkx_labels(G, pos, labels = node_labels)
        edge_labels = nx.get_edge_attributes(G, 'weight')
        nx.draw_networkx_edge_labels(G, pos, edge_labels=edge_labels, with_labels=True)

        # Plot it
        # nx.draw(G, with_labels=True)
        plt.show()

    def plot_path(self, path):
        # Build your graph
        G = nx.DiGraph()
        L = int(sqrt(self.nodes))
        perfect_sqrt = (self.nodes % L) == 0

        add_one = (self.nodes % 2 is not 0) and (not perfect_sqrt)

        for node in range(self.nodes):
            posx = node % L
            posy = L-1-int(node / L)
            # posy = int(node / L)
            G.add_node(node, pos=(posx,posy))
            # print(f'Node {node} ({posx}, {posy})')

        for v in G.nodes:
            G.nodes[v]['state']= v
        print('\n')
        for nos, custo in self.graph.get_relacoes().items():
            G.add_edge(nos[0], nos[1], weight=custo)
            # print(f'Edge ({node[0]}, {node[1]}, {node[2]})')


        pos=nx.get_node_attributes(G, 'pos')
        nx.draw(G, pos)
        node_labels = nx.get_node_attributes(G,'state')
        nx.draw_networkx_labels(G, pos, labels = node_labels)
        edge_labels = nx.get_edge_attributes(G, 'weight')
        nx.draw_networkx_edge_labels(G, pos, edge_labels=edge_labels, with_labels=True)

        # adicionando caminho
        path_edges = list(zip(list(path),list(path)[1:]))
        nx.draw_networkx_nodes(G, pos, nodelist=set(path), node_color='r')
        nx.draw_networkx_edges(G,pos,edgelist=path_edges, edge_color='r')

        plt.show()

    def plot_path_obstaculo(self, path, obstaculos):
        # Build your graph
        G = nx.DiGraph()
        L = int(sqrt(self.nodes))
        perfect_sqrt = (self.nodes % L) == 0

        add_one = (self.nodes % 2 is not 0) and (not perfect_sqrt)

        for node in range(self.nodes):
            posx = node % L
            posy = L-1-int(node / L)
            G.add_node(node, pos=(posx, posy))

        for v in G.nodes:
            G.nodes[v]['state']= v
        print('\n')
        for nos, custo in self.graph.get_relacoes().items():
            G.add_edge(nos[0], nos[1], weight=custo)

        pos=nx.get_node_attributes(G, 'pos')
        nx.draw(G, pos)
        node_labels = nx.get_node_attributes(G,'state')
        nx.draw_networkx_labels(G, pos, labels = node_labels)
        edge_labels = nx.get_edge_attributes(G, 'weight')
        nx.draw_networkx_edge_labels(G, pos, edge_labels=edge_labels, with_labels=True)

        # adicionando caminho
        path_edges = list(zip(list(path),list(path)[1:]))
        nx.draw_networkx_nodes(G, pos, nodelist=set(path), node_color='r')
        nx.draw_networkx_edges(G, pos, edgelist=path_edges, edge_color='r')

        # list_obstaculos = []
        # list_obstaculos_nodes = []
        #
        # for endereco, posicao in obstaculos.mem.items():
        #     for vizinho in posicao:
        #         if vizinho[1]:
        #             list_obstaculos.append((endereco, vizinho[0]))
        #             list_obstaculos_nodes.append(vizinho[0])
        # list_obstaculos_nodes = set(list_obstaculos_nodes)

        list_obstaculos, list_obstaculos_nodes = obstaculos
        nx.draw_networkx_edges(G, pos, edgelist=set(list_obstaculos), edge_color='w')
        nx.draw_networkx_nodes(G, pos, nodelist=set(list_obstaculos_nodes), node_color='w')


        plt.show()

    def criar_obstaculos(self, num, fonte, destino):
        count = 0
        list_obstaculos = []
        random.seed(num)
        while count < num:
            node = random.randint(1, len(self.graph.nos)-1)
            if node != fonte and node != destino and count < num:
                list_obstaculos.append(node)
                count += 1
        return list_obstaculos


if __name__ == '__main__':
    graph_gen = GraphGen(max_weigth=10)
    graph_gen.adjacent_lis(nodes=16)
    graph_gen.plot()

