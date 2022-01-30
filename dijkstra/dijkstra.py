from collections import deque, namedtuple
import time
import datetime

# we'll use infinity as a default distance to nodes.
inf = float('inf')
Edge = namedtuple('Edge', 'start, end, cost')


def make_edge(start, end, cost=1):
  return Edge(start, end, cost)


class Graph:
    def __init__(self, edges):
        # let's check that the data is right
        wrong_edges = [i for i in edges if len(i) not in [2, 3]]
        if wrong_edges:
            raise ValueError('Wrong edges data: {}'.format(wrong_edges))
        print(f'Criando bordas...')
        self.edges = [make_edge(*edge) for edge in edges]
        print(f'Criando vertices...')
        self.vertices = self.d_vertices()
        print(f'Criando vizinhos...')
        self.neighbours = self.d_neighbours()


    # @property
    def d_vertices(self):
        return set(
            sum(
                ([edge.start, edge.end] for edge in self.edges), []
            )
        )

    # def get_node_pairs(self, n1, n2, both_ends=True):
    #     if both_ends:
    #         node_pairs = [[n1, n2], [n2, n1]]
    #     else:
    #         node_pairs = [[n1, n2]]
    #     return node_pairs
    #
    # def remove_edge(self, n1, n2, both_ends=True):
    #     node_pairs = self.get_node_pairs(n1, n2, both_ends)
    #     edges = self.edges[:]
    #     for edge in edges:
    #         if [edge.start, edge.end] in node_pairs:
    #             self.edges.remove(edge)
    #
    # def add_edge(self, n1, n2, cost=1, both_ends=True):
    #     node_pairs = self.get_node_pairs(n1, n2, both_ends)
    #     for edge in self.edges:
    #         if [edge.start, edge.end] in node_pairs:
    #             return ValueError('Edge {} {} already exists'.format(n1, n2))
    #
    #     self.edges.append(Edge(start=n1, end=n2, cost=cost))
    #     if both_ends:
    #         self.edges.append(Edge(start=n2, end=n1, cost=cost))

    # @property
    def d_neighbours(self):
        neighbours = {vertex: set() for vertex in self.vertices}
        for edge in self.edges:
            neighbours[edge.start].add((edge.end, edge.cost))

        return neighbours

    def dijkstra(self, source, dest):
        assert source in self.vertices, 'Such source node doesn\'t exist'
        distances = {vertex: inf for vertex in self.vertices}
        previous_vertices = {
            vertex: None for vertex in self.vertices
        }
        # Inicialização fonte
        distances[source] = 0
        vertices = self.vertices.copy()

        while vertices:
            current_vertex = min(vertices, key=lambda vertex: distances[vertex])
            vertices.remove(current_vertex)
            if distances[current_vertex] == inf:
                break
            for neighbour, cost in self.neighbours[current_vertex]:
                # Compara a distância do vizinho para a fonte com a distância da rota alternativa até a fonte
                alternative_route = distances[current_vertex] + cost
                distaces_neighbour = distances[neighbour]
                if alternative_route < distaces_neighbour:
                    distances[neighbour] = alternative_route
                    previous_vertices[neighbour] = current_vertex

        path, current_vertex = deque(), dest
        while previous_vertices[current_vertex] is not None:
            path.appendleft(current_vertex)
            current_vertex = previous_vertices[current_vertex]
        if path:
            path.appendleft(current_vertex)
        return path


if __name__ == '__main__':
    # graph = Graph([
    #     ("a", "b", 7),  ("a", "c", 9),  ("a", "f", 14), ("b", "c", 10),
    #     ("b", "d", 15), ("c", "d", 11), ("c", "f", 2),  ("d", "e", 6),
    #     ("e", "f", 9)])
    from util.random_graph import GraphGen
    from pyprof2calltree import visualize
    import cProfile
    import re

    print(f'Criando Lista de adjacência...')
    gen_graph = GraphGen(max_weigth=10)
    num_nodes = 10
    adjacent_lis = gen_graph.adjacent_lis(num_nodes)
    # print(adjacent_lis)
    # gen_graph.plot()
    print(f'Iniciando Grafo')
    iniciot = time.time()
    graph = Graph(adjacent_lis)


    # cProfile.run('graph.dijkstra(0, 15)')
    # cProfile.run('graph.dijkstra(1, 20)', filename='dijkstra.cprof')
    # visualize('dijkstra.cprof')

    print(f'Iniciando Dijkstra...\n')
    inicio = time.time()
    path = graph.dijkstra(0, num_nodes-1)

    fim = time.time()
    print(f"Tempo Dijkstra = {str(fim - inicio)}")
    print(f"Tempo Total = {str(fim - iniciot)}")
    print(path)
    
    # gen_graph.plot()
    gen_graph.plot_path(path)