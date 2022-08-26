class LocalizadorVizinhosValidos():
    def __init__(self):
        self.mem_relacoes = None
        self.mem_estabelecidos = None
        self.local_buffer = {}
        self.hit = 0
        self.miss = 0

    def get_len_buffer(self):
        return len(self.local_buffer)

    def inicializar_mem(self, mem_relacoes, mem_estabelecidos):
        self.mem_relacoes = mem_relacoes
        self.mem_estabelecidos = mem_estabelecidos

    def buscar_memoria(self, no):
        self.miss += 1
        self.local_buffer[no] = self.mem_relacoes.ler(no)

    def remover_do_buffer(self, no):
        self.local_buffer.pop(no)

    def get_menor_vizinho(self, no):
        """Retorna o menor vizinho que não é obstáculo"""
        if no in self.local_buffer.keys():
            self.hit += 1
            relacoes = self.local_buffer[no]
            for relacao, obstaculo, custo in relacoes:
                if obstaculo == 0:
                    return relacao, obstaculo, custo
        else:
            self.buscar_memoria(no)
            return self.get_menor_vizinho(no)

    def get_relacoes(self, no):
        """Retorna as relações de um nó que não são obstáculos"""
        if no in self.local_buffer.keys():
            self.hit += 1
            relacoes = self.local_buffer[no]
            relacoes_validas = []
            for relacao, obstaculo, custo in relacoes:
                if obstaculo == 0:
                    # Remove os nós estabelecidos
                    if self.mem_estabelecidos.ler(relacao) == 0:
                        # Para quando tiver um obstáculo e não houver vizinho válido
                        if self.get_menor_vizinho(relacao):
                            relacoes_validas.append([relacao, custo, self.get_menor_vizinho(relacao)[2]])
            return relacoes_validas
        else:
            self.buscar_memoria(no)
            return self.get_relacoes(no)


