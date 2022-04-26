from dijkstra_paralel.atualizador_vizinhos import AtualizadorVizinhos
from dijkstra_paralel.avaliador_ativos import Avaliador_ativos
from dijkstra_paralel.formador_caminhos import FormadorCaminho
from dijkstra_paralel.gerenciador_memoria import Memoria, MemoriaInt
from dijkstra_paralel.localizador_vizinhos_validos import LocalizadorVizinhosValidos
from dijkstra_otimizado.dijkstra_out_sequencial import main as main_sequencial
from dijkstra.dijkstra_crauser import main as main_crauser
from crauser.random_graph import GraphGen
import warnings
inf = float('inf')

class DijkstraParallel():
    def __init__(self, num_nos, max_num_vizinhos):
        self.fonte = None
        self.destino = None
        self.num_nos = num_nos
        self.max_num_vizinhos = max_num_vizinhos
        # Criando Blocos
        self.mem_anterior = MemoriaInt(num_nos, 1)
        self.mem_estabelecidos = MemoriaInt(num_nos, 1)
        self.mem_relacoes = Memoria(num_nos, max_num_vizinhos)
        self.mem_obstaculos = Memoria(num_nos, max_num_vizinhos)
        self.avaliador_ativos = Avaliador_ativos()
        self.lvv = LocalizadorVizinhosValidos()
        self.av = AtualizadorVizinhos()
        self.fc = FormadorCaminho()

    def inicializar_mem(self, grafo):
        for no in grafo.nos:
            relacoes = grafo.get_relacoes_vizinhos(no)
            relacoes = dict(sorted(relacoes.items(), key=lambda item: item[1]))
            relacoes_list = []
            obstaculo_list = []
            for relacao, custo in relacoes.items():
                relacoes_list.append((relacao[1], custo))
                obstaculo_list.append((relacao[1], 0))
            """Inicializando memória de relações"""
            self.mem_relacoes.escrever(no, relacoes_list)
            """Inicializando memória de obstáculos"""
            self.mem_obstaculos.escrever(no, obstaculo_list)
            """Inicializando memória de estabelecidos"""
            self.mem_estabelecidos.escrever(no, 0)
            """Repassando as memórias para o LVV"""
            self.lvv.inicializar_mem(self.mem_relacoes, self.mem_obstaculos, self.mem_estabelecidos)

    def calcular_caminho(self, fonte, destino):
        # Inicializando com a fonte
        menor_vizinho = self.lvv.get_menor_vizinho(fonte)
        self.avaliador_ativos.inserir_no_buffer(distancia=0, endereco=fonte, menor_vizinho=menor_vizinho[1])

        # Busca até o avaliador de ativos estar vázio
        while self.avaliador_ativos.tem_ativo_no_buffer():
            buffer0 = []
            buffer1 = []
            buffer2 = []

            aprovados_distancia = self.avaliador_ativos.get_aprovados_no_buffer()

            for aprovado, distancia_v in aprovados_distancia:
                """Estabelecendo os nós aprovados"""
                self.avaliador_ativos.remover_no_buffer(aprovado)
                self.lvv.remover_do_buffer(aprovado)
                self.mem_estabelecidos.escrever(endereco=aprovado, valor=1)
                buffer0.append([aprovado, distancia_v])

            for [aprovado, distancia_v] in buffer0:
                """Encontrando os vizinhos de um nó aprovado"""
                relacoes_aprovado = self.lvv.get_relacoes_e_menor_vizinho(aprovado)
                for [endereco_w, custo_vw, menor_vizinho] in relacoes_aprovado:
                    """Transformando em um buffer para aumentar o paralelismo, 
                    basicamente transformando de 2d para 1d"""
                    buffer1.append([endereco_w, custo_vw, menor_vizinho, aprovado, distancia_v])

            for [endereco_w, custo_vw, menor_vizinho, aprovado, distancia_v] in buffer1:
                """Atualizando os vizinhos do nó aprovado, o atualizador de vizinhos foi removido devido a necessidade de acessar a memṕria 
                para consultar a distancia de w, desse modo a distancia só é consultada na etapa final do pipeline"""
                distancia_vw = distancia_v + custo_vw
                buffer2.append([endereco_w, aprovado, distancia_vw, menor_vizinho])

            for [endereco_w, anterior, distancia_vw, menor_vizinho] in buffer2:
                """A nova distância deve ser comparada com a distância armazenada, pois outro nó pode ter atualizado com 
                uma distância menor do que a atual"""
                if self.avaliador_ativos.get_distancia_no_buffer(endereco_w) > distancia_vw:
                    self.avaliador_ativos.inserir_no_buffer(distancia=distancia_vw,
                                                            endereco=endereco_w,
                                                            menor_vizinho=menor_vizinho)
                    self.mem_anterior.escrever(endereco=endereco_w, valor=anterior)

        return self.fc.gerar_caminho(fonte, destino, self.mem_anterior)


def main(num_nos=10, debug=False, grafico=False):
    # num_nos = 5
    fonte = 3
    destino = num_nos-1

    top = DijkstraParallel(num_nos=num_nos, max_num_vizinhos=6)
    graph_gen = GraphGen(max_weigth=10)
    graph_gen.adjacent_lis(nodes=num_nos)
    top.inicializar_mem(graph_gen.graph)
    menor_caminho = top.calcular_caminho(fonte=fonte, destino=destino)
    custo = graph_gen.graph.get_custo_caminho(menor_caminho)
    if grafico:
        graph_gen.plot_path(menor_caminho)
    return menor_caminho, custo


if __name__ == '__main__':
    # teste = False
    # grafico = True
    teste = True
    grafico = False
    num_nos = 128
    inicio = 5

    if not teste:
        inicio = num_nos - 1

    for idx in range(inicio, num_nos):
        caminho, custo = main(num_nos=idx, debug=False, grafico=grafico)
        caminho2, custo2 = main_sequencial(num_nos=idx, debug=False, grafico=grafico)

        if custo != custo2:
            warnings.warn(f"Foram encontrados erros: num de nós {idx}")
            print(f"Referência {caminho2, custo2}")
            print(f"Modelo {caminho, custo}")
            break

        else:
            print(f"Passou {idx}!")
    print(f"Passou!")
