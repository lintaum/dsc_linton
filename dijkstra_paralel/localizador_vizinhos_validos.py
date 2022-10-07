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
        """Retorna o custo do menor vizinho que não é obstáculo"""
        if no in self.local_buffer.keys():
            self.hit += 1
            relacoes = self.local_buffer[no]
            for relacao, obstaculo, custo in relacoes:
                """Essa verificação de obstáculo ira reduzir a quantidade de acessos a memoria de 
                relações e a quantidade de informações armazenadas no buffer, no entanto, 
                será necessário inserir uma verificação na memória de obstáculos"""
                if obstaculo == 0:
                    return custo
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
                    """Ignora os nós já estabelecidos, essa verificação prévia refuz pela metade a quantidade de nós a 
                    serem analisados. No entanto, será necessário realizar essa checagem novamente no passo 3."""
                    if self.mem_estabelecidos.ler(relacao) == 0:
                        # Verifica se tem obstáculos e não há vizinho válido
                        if self.get_menor_vizinho(relacao):
                            relacoes_validas.append([relacao, custo, self.get_menor_vizinho(relacao)])
            return relacoes_validas
        else:
            self.buscar_memoria(no)
            return self.get_relacoes(no)


