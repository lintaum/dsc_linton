class Relacao():
    """Define uma relação entre dois nós do grafos com um peso"""
    def __init__(self, no_origem, no_destino, peso):
        self.nos = (no_origem, no_destino)
        self.peso = peso

    def get(self):
        return self.nos

    def set(self, no_1, no_2, peso):
        self.nos = (no_1, no_2, peso)
        self.peso = peso


class Grafo():
    """Conjunto de relações entre os nós
        definições do grafo:
            - Não existe mais de um caminho entre dois nós
    """
    def __init__(self):
        self.relacoes = []
        self.nos = []

    def add_relacao(self, no_1, no_2, peso):
        self.relacoes.append(Relacao(no_1, no_2, peso))

    def add_no(self, no):
        self.nos.append(no)

    def get_relacoes(self):
        """retorna todas as relações do grafo"""
        return self.relacoes

    def get_relacoes_no(self, no):
        """retorna as relações de um nó"""
        relacoes = []
        for relacao in self.relacoes:
            if no in relacao.nos:
                relacoes.append(relacao)
        return relacoes

    def get_custo(self, no_1, no_2):
        """retorna o custo entre dois nós vizinhos"""
        custo = 0
        for relacao in self.get_relacoes_vizinhos(no_1):
            if relacao.nos[1] is no_2:
                return relacao.peso

    def get_menor_vizinho(self, no):
        """Retorna o vizinho com a menor distância"""
        relacoes = self.get_relacoes_no(no)
        menor = None
        for vizinho in relacoes:
            if menor:
                if vizinho.peso < menor.peso:
                    menor = vizinho
            else:
                menor = vizinho
        return menor

    def get_vizinhos(self, no):
        """Retorna uma lista com os nós vizinhos"""
        vizinhos = []
        relacoes_vizinho = self.get_relacoes_no(no)
        for relacao in relacoes_vizinho:
            vizinhos.append(relacao.nos[0])
            vizinhos.append(relacao.nos[1])

        vizinhos = set(vizinhos)
        vizinhos.remove(no)
        return vizinhos

    def get_relacoes_vizinhos(self, no):
        """Retorna as relações que partem de um nó"""
        relacoes = self.get_relacoes_no(no)
        relacoes_vizinhas = []
        for relacao in relacoes:
            if relacao.nos[0] is no:
                relacoes_vizinhas.append(relacao)
        return relacoes_vizinhas

