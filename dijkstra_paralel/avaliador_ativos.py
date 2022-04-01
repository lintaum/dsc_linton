inf = float('inf')

class NoAtivo():
    """Estrutura básica de um nó ativo"""
    def __init__(self, menor_vizinho, distancia, endereco):
        self.menor_vizinho = menor_vizinho
        self.distancia = distancia
        self.criterio = distancia + menor_vizinho
        self.endereco = endereco

    def __str__(self):
        return f"Vizinho: {self.menor_vizinho}, Distancia: {self.distancia}, Criterio: {self.criterio}"

    def atualizar_distancia(self, nova_distancia):
        self.distancia = nova_distancia
        self.criterio = nova_distancia + self.menor_vizinho


class Avaliador_ativos():
    """Insere e remove os nós ativos, calcula o critério de classificação e seleciona os aprovados"""
    BUFF_SIZE = 12

    def __init__(self):
        self.ativos = {}
        self.aprovados = {}
        self.buff_count = 0

    def get_distancia(self, endereco):
        if endereco in self.ativos.keys():
            return self.ativos[endereco].distancia
        return inf

    def inserir(self, distancia, menor_vizinho, endereco):
        self.ativos[endereco] = NoAtivo(menor_vizinho=menor_vizinho, distancia=distancia, endereco=endereco)

    def remover_no(self, endereco):
        self.ativos.pop(endereco)

    def tem_ativo(self):
        return len(self.ativos) > 0

    def atualizar_distancia(self, endereco, nova_distancia):
        """Para quando uma distância tiver que ser atualizada"""
        self.ativos[endereco].atualizar_distancia(nova_distancia)

    def get_criterio_out(self):
        # TODO: Melhorar para o paralelismo
        criterio = float('inf')
        for endereco, no in self.ativos.items():
            if no.criterio < criterio:
                criterio = no.criterio
        return criterio

    def get_aprovados(self):
        criterio = self.get_criterio_out()
        aprovados = []
        for endereco, no in self.ativos.items():
            if no.distancia <= criterio:
                aprovados.append([endereco, self.get_distancia(endereco)])
        return aprovados


if __name__ == '__main__':
    aa = Avaliador_ativos()
    aa.inserir(distancia=7, menor_vizinho=0, endereco=1)
    aa.inserir(distancia=4, menor_vizinho=1, endereco=2)
    aa.inserir(distancia=2, menor_vizinho=3, endereco=3)
    aa.inserir(distancia=8, menor_vizinho=7, endereco=4)
    # aa.remover_no(5)
    aa.atualizar_distancia(1, 10)
    aa.tem_ativo()
    aprovados = aa.get_aprovados()
    print("Iniciando teste")
