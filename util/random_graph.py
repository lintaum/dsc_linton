from random import random, randint

class GraphGen:
    # def __init__(self, nodes):
    #     self.nodes = nodes

    def adjacent_lis(self, nodes):
        # inserir semente
        graph = []
        for n in range(nodes):
            node = (n, nodes-n, randint(1, nodes))
            graph.append(node)
        return graph


if __name__ == '__main__':
    GraphGen().adjacent_lis(2500)
