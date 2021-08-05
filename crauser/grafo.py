# class Relacao():
#     """Define uma relação entre dois nós do grafos com um peso"""
#     def __init__(self, no_origem, no_destino, peso):
#         self.nos = (no_origem, no_destino)
#         self.peso = peso
#
#     def get(self):
#         return self.nos
#
#     def set(self, no_1, no_2, peso):
#         self.nos = (no_1, no_2, peso)
#         self.peso = peso
#
#     def __str__(self, *args, **kwargs):
#         return f"{self.nos[0]}->{self.nos[1]}"


class Grafo():
    """Conjunto de relações entre os nós
        definições do grafo:
            - Não existe mais de um caminho entre dois nós
    """
    def __init__(self):
        self.relacoes = {}
        self.nos = []

    def add_relacao(self, no_1, no_2, peso):
        self.relacoes[(no_1, no_2)]=peso
        # self.relacoes.append(Relacao(no_1, no_2, peso))

    def add_no(self, no):
        self.nos.append(no)

    def get_relacoes(self):
        """retorna todas as relações do grafo"""
        return self.relacoes

    def get_relacoes_no(self, no):
        """retorna as relações de um nó"""
        relacoes = {}
        for relacao, custo in self.relacoes.items():
            if no in relacao:
                relacoes[relacao]=custo
        return relacoes

    def get_custo(self, no_1, no_2):
        """retorna o custo entre dois nós vizinhos"""
        if (no_1, no_2) in self.relacoes.keys():
            return self.relacoes[(no_1, no_2)]
        # for relacao, custo in self.get_relacoes_vizinhos(no_1).items():
        #     if relacao[1] == no_2:
        #         return custo

    def get_menor_vizinho(self, no):
        """Retorna o custo do vizinho com a menor distância"""
        relacoes = self.get_relacoes_no(no)
        menor = None
        for vizinho, vizinho_custo in relacoes.items():
            if menor:
                if vizinho_custo < menor:
                    menor = vizinho_custo
            else:
                menor = vizinho_custo
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
        relacoes_vizinhas = {}
        for relacao, custo in relacoes.items():
            if relacao[0] == no:
                relacoes_vizinhas[(relacao)]=custo
        return relacoes_vizinhas

    def get_relacoes_vizinhos_in(self, no):
        """Retorna as relações que chegam em um nó"""
        relacoes = self.get_relacoes_no(no)
        relacoes_vizinhas = {}
        for relacao, custo in relacoes.items():
            if relacao[1] == no:
                relacoes_vizinhas[relacao]=custo
        # print(f"Vizinhos in: {relacoes_vizinhas} do nó {no}")
        return relacoes_vizinhas

    def get_menor_vizinho_in(self, no):
        """Retorna o vizinho que chega com a menor distância"""
        relacoes = self.get_relacoes_vizinhos_in(no)
        menor_custo = None
        menor_vizinho = None
        for vizinho, vizinho_custo in relacoes.items():
            if menor_custo:
                if vizinho_custo < menor_custo:
                    menor_custo = vizinho_custo
                    menor_vizinho = vizinho
            else:
                menor_custo = vizinho_custo
                menor_vizinho = vizinho
        # return {(menor_vizinho):menor_custo}
        return menor_custo

    def get_custo_caminho(self, caminho):
        custo = 0
        no_1 = None
        for no in caminho:
            if no_1:
                custo+=self.get_custo(no_1, no)
            no_1=no
        return custo
