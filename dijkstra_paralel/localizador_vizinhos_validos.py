class LocalizadorVizinhosValidos():
    def __init__(self):
        self.mem_relacoes = None
        self.mem_obstaculos = None
        self.mem_estabelecidos = None
        self.local_buffer = {}

    def inicializar_mem(self, mem_relacoes, mem_obstaculos, mem_estabelecidos):
        self.mem_relacoes = mem_relacoes
        self.mem_obstaculos = mem_obstaculos
        self.mem_estabelecidos = mem_estabelecidos

    def buscar_memoria(self, no):
        relacoes = self.mem_relacoes.ler(no)
        obstaculos = self.mem_obstaculos.ler(no)
        self.local_buffer[no] = [relacoes, obstaculos]

    def get_menor_vizinho(self, no):
        """Retorna o menor vizinho que não é obstáculo"""
        if no in self.local_buffer.keys():
            relacoes, obstaculos = self.local_buffer[no]
            count = 0
            for obstaculo in obstaculos:
                if obstaculo[1] == 0:
                    return relacoes[count]
                count += 1
        else:
            self.buscar_memoria(no)
            return self.get_menor_vizinho(no)

    def get_relacoes(self, no):
        """Retorna as relações de um nó que não são obstáculos"""
        if no in self.local_buffer.keys():
            relacoes, obstaculos = self.local_buffer[no]
            count = 0
            relacoes_validas = []
            for obstaculo in obstaculos:
                if obstaculo[1] == 0:
                    if self.mem_estabelecidos.ler(relacoes[count][0]) == 0:
                        relacoes_validas.append(relacoes[count])
                count += 1
            return relacoes_validas
        else:
            self.buscar_memoria(no)
            return self.get_relacoes(no)
