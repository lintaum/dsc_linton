inf = float('inf')

class NoAtivo():
    """Estrutura básica de um nó ativo"""
    def __init__(self, menor_vizinho, distancia, endereco, ocupado=True):
        self.menor_vizinho = menor_vizinho
        self.distancia = distancia
        self.criterio = distancia + menor_vizinho
        self.endereco = endereco
        self.ocupado = ocupado

    def __str__(self):
        return f"Menor Vizinho: {self.menor_vizinho}, Distancia: {self.distancia}, Criterio: {self.criterio}, Ocupado: {self.ocupado}, Endereço {self.endereco}"

    def atualizar_distancia(self, nova_distancia):
        self.distancia = nova_distancia
        self.criterio = nova_distancia + self.menor_vizinho


class Avaliador_ativos():
    """Insere e remove os nós ativos, calcula o critério de classificação e seleciona os aprovados"""
    BUFF_SIZE = 64

    def __init__(self):
        self.buffer_ativos = dict.fromkeys(range(self.BUFF_SIZE), NoAtivo(menor_vizinho=0, distancia=0, endereco=0, ocupado=False))
        # self.ativos = {}
        # self.aprovados = {}

    def get_buff_addr(self, endereco):
        # Identifica o endereço no buffer em que o nó está armazenado. No FPGA isso vai ser em paralelo
        for endereco_buffer, no in self.buffer_ativos.items():
            if no.endereco == endereco and no.ocupado:
                return endereco_buffer
        return None

    def get_buffer_vazio(self):
        # Identifica o espaço no buffer que está vazio e apto para receber dados
        for endereco_buffer, no in self.buffer_ativos.items():
            if not no.ocupado:
                return endereco_buffer

    def inserir_no_buffer(self, distancia, menor_vizinho, endereco):
        endereco_buffer = self.get_buff_addr(endereco)
        if endereco_buffer is None:
            endereco_buffer = self.get_buffer_vazio()
        if endereco_buffer is None:
            print("Estouro do buffer")
            # break
            return False
        self.buffer_ativos[endereco_buffer] = NoAtivo(menor_vizinho=menor_vizinho, distancia=distancia, endereco=endereco, ocupado=True)

    def remover_no_buffer(self, endereco):
        endereco_buffer = self.get_buff_addr(endereco)
        self.buffer_ativos[endereco_buffer].ocupado = False

    def get_distancia_no_buffer(self, endereco):
        endereco_buffer = self.get_buff_addr(endereco)
        if endereco_buffer is not None:
            return self.buffer_ativos[endereco_buffer].distancia
        return inf

    def tem_ativo_no_buffer(self):
        for endereco_buffer, no in self.buffer_ativos.items():
            if no.ocupado:
                return True
        return False

    def atualizar_distancia_no_buffer(self, endereco, nova_distancia):
        """Para quando uma distância tiver que ser atualizada"""
        endereco_buffer = self.get_buff_addr(endereco)
        self.buffer_ativos[endereco_buffer].atualizar_distancia(nova_distancia)

    def get_criterio_out_no_buffer(self):
        # TODO: Melhorar para o paralelismo
        criterio = float('inf')
        for no in self.buffer_ativos.values():
            if no.criterio < criterio and no.ocupado:
                criterio = no.criterio
        return criterio


    def get_aprovados_no_buffer(self):
        criterio = self.get_criterio_out_no_buffer()
        aprovados = []
        for endereco, no in self.buffer_ativos.items():
            if no.distancia <= criterio and no.ocupado:
                aprovados.append([no.endereco, self.get_distancia_no_buffer(no.endereco)])
        return aprovados

    # def get_distancia(self, endereco):
    #     if endereco in self.ativos.keys():
    #         return self.ativos[endereco].distancia
    #     return inf
    #
    # def inserir(self, distancia, menor_vizinho, endereco):
    #     self.ativos[endereco] = NoAtivo(menor_vizinho=menor_vizinho, distancia=distancia, endereco=endereco)

    # def remover_no(self, endereco):
    #     self.ativos.pop(endereco)

    # def tem_ativo(self):
    #     return len(self.ativos) > 0

    # def atualizar_distancia(self, endereco, nova_distancia):
    #     """Para quando uma distância tiver que ser atualizada"""
    #     self.ativos[endereco].atualizar_distancia(nova_distancia)

    # def get_criterio_out(self):
    #     # TODO: Melhorar para o paralelismo
    #     criterio = float('inf')
    #     for endereco, no in self.ativos.items():
    #         if no.criterio < criterio:
    #             criterio = no.criterio
    #     return criterio

    # def get_aprovados(self):
    #     criterio = self.get_criterio_out()
    #     aprovados = []
    #     for endereco, no in self.ativos.items():
    #         if no.distancia <= criterio:
    #             aprovados.append([endereco, self.get_distancia(endereco)])
    #     return aprovados


if __name__ == '__main__':
    aa = Avaliador_ativos()
    aa.inserir_no_buffer(distancia=7, menor_vizinho=0, endereco=1)
    aa.inserir_no_buffer(distancia=4, menor_vizinho=1, endereco=2)
    aa.inserir_no_buffer(distancia=2, menor_vizinho=3, endereco=3)
    aa.inserir_no_buffer(distancia=8, menor_vizinho=7, endereco=4)
    # aa.remover_no(5)
    aa.atualizar_distancia_no_buffer(1, 10)
    aa.tem_ativo_no_buffer()
    aprovados = aa.get_aprovados_no_buffer()
    print("Iniciando teste")
