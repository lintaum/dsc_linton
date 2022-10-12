from dijkstra_paralel.atualizador_vizinhos import AtualizadorVizinhos
from dijkstra_paralel.avaliador_ativos import AvaliadorAtivos
from dijkstra_paralel.formador_caminhos import FormadorCaminho
from dijkstra_paralel.gerenciador_memoria import Memoria, MemoriaInt
from dijkstra_paralel.localizador_vizinhos_validos import LocalizadorVizinhosValidos
from dijkstra_otimizado.dijkstra_out_sequencial import main as main_sequencial
from dijkstra.dijkstra_crauser import main as main_crauser
from crauser.random_graph import GraphGen
import warnings

from util.gen_mem_files import dict_2_vmem

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
        self.avaliador_ativos = AvaliadorAtivos()
        self.lvv = LocalizadorVizinhosValidos()
        self.av = AtualizadorVizinhos()
        self.fc = FormadorCaminho()

    def inicializar_mem(self, grafo, obstaculos):
        # print(f"Obstaculos: {obstaculos}")
        for no in grafo.nos:
            relacoes = grafo.get_relacoes_vizinhos(no)
            relacoes = dict(sorted(relacoes.items(), key=lambda item: item[1]))
            obstaculo_list = []
            relacao_list = []

            for relacao, custo in relacoes.items():
                if relacao[1] in obstaculos:
                    relacao_list.append((relacao[1], 1, custo))
                    obstaculo_list.append((relacao[1], 1))
                else:
                    relacao_list.append((relacao[1], 0, custo))
                    obstaculo_list.append((relacao[1], 0))

            """Inicializando memória de relações"""
            self.mem_relacoes.escrever(no, relacao_list)
            # self.mem_obstaculos.escrever(no, obstaculo_list)
            """Inicializando memória de estabelecidos"""
            self.mem_estabelecidos.escrever(no, 0)
            """Repassando as memórias para o LVV"""
            self.lvv.inicializar_mem(self.mem_relacoes, self.mem_estabelecidos)
        dict_2_vmem(self.mem_relacoes, obstaculos)

    def calcular_caminho(self, fonte, destino):
        # sinais de debug
        num_passo1 = 0
        num_passo2 = 0
        num_passo3 = 0
        # Inicializando com a fonte
        self.avaliador_ativos.inserir_no_buffer(distancia=0, endereco=fonte, menor_vizinho=0)

        # Busca até o avaliador de ativos estar vázio
        max_aprovados = 0
        max_buffer_lvv = 0
        while self.avaliador_ativos.tem_ativo_no_buffer():
            """Passo 1 - Identificando aprovados"""
            buffer00 = []
            aprovados_distancia = self.avaliador_ativos.get_aprovados_no_buffer()
            for aprovado, distancia_v in aprovados_distancia:
                num_passo1 += 1
                """salvando no buffer de saida"""
                buffer00.append([aprovado, distancia_v])

            """Passo 2 - Encontrando vizinhos e estabelecendo"""
            buffer10 = []
            for [aprovado, distancia_v] in buffer00:
                """Estabelecendo os nós aprovados e removendo do gerenciador de ativos"""
                self.mem_estabelecidos.escrever(endereco=aprovado, valor=1)
                self.avaliador_ativos.remover_no_buffer(aprovado)
                """Encontrando os vizinhos de um nó aprovado"""
                relacoes_aprovado = self.lvv.get_relacoes(aprovado)
                for [endereco_w, custo_vw, menor_vizinho] in relacoes_aprovado:
                    num_passo2 += 1
                    """Transformando em um buffer para aumentar o paralelismo, 
                    basicamente transformando de 2d para 1d"""
                    buffer10.append([endereco_w, custo_vw, menor_vizinho, aprovado, distancia_v])
                """Removendo o nó aprovado do buffer em LVV"""
                self.lvv.remover_do_buffer(aprovado)

            """Passo 3 - Calculando a distância e atualizando"""
            for [endereco_w, custo_vw, menor_vizinho, aprovado, distancia_v] in buffer10:
                """Atualizando os vizinhos do nó aprovado, 
                O atualizador de vizinhos foi removido devido a necessidade de acessar a memória para consultar a 
                distancia de w, desse modo a distancia só é consultada na etapa final do pipeline, isso aumenta o 
                gasto computacional pois sempre irá analisar todos os nós, no entanto, reduz e centraliza o acesso 
                de leitura aos buffer do avaliador de ativos. A nova distância deve ser comparada com a distância 
                armazenada, pois outro nó pode ter atualizado com uma distância menor do que a atual"""
                if self.mem_estabelecidos.ler(endereco_w) == 0:
                    num_passo3 += 1
                    distancia_vw = distancia_v + custo_vw
                    if self.avaliador_ativos.get_distancia_no_buffer(endereco_w) > distancia_vw:
                        self.avaliador_ativos.inserir_no_buffer(distancia=distancia_vw,
                                                                endereco=endereco_w,
                                                                menor_vizinho=menor_vizinho)
                        self.mem_anterior.escrever(endereco=endereco_w, valor=aprovado)

            # Informaçoes para Debug
            if len(buffer00) > max_aprovados:
                max_aprovados = len(buffer00)
            if self.lvv.get_len_buffer() > max_buffer_lvv:
                max_buffer_lvv = self.lvv.get_len_buffer()
        """ O hit e miss são influenciados pela quantidade de obstáculos, quanto mais obstáculos mais nós não são 
        alcançados e conseguentemente menos nós são analisados, em grafos sem obstáculos a quantidade de miss é igual a 
        quantidade de nós.
        0 obstáculos 7.6x mais hit
        1/5 de obstáculos temos 6x mais hit
        1/4 de obstáculos temos 6x mais hit
        1/3 de obstáculos temos 5x mais hit
        1/2 de obstáculos temos 5x mais hit"""

        print(f"Max Aprovados: {max_aprovados}, "
              f"Max Ativos: {self.avaliador_ativos.max_ocupacao}, "
              f"Max Buffer LVV: {max_buffer_lvv}; "
              f"Hit {self.lvv.hit}, "
              f"Miss {self.lvv.miss} "
              f"Hit/Miss {round(self.lvv.hit/self.lvv.miss, 2)} "
              f"Passo1: {num_passo1}, Passo2: {num_passo2}, Passo3: {num_passo3}, ")

        return self.fc.gerar_caminho(fonte, destino, self.mem_anterior)


def main(num_nos=10, debug=False, grafico=False, num_onstaculos=10):
    # num_nos = 5
    fonte = 0
    destino = num_nos-1

    """Gerando o grafo"""
    top = DijkstraParallel(num_nos=num_nos, max_num_vizinhos=6)
    graph_gen = GraphGen(max_weigth=15)
    graph_gen.adjacent_lis(nodes=num_nos)

    """Definindo os obstáculos"""
    obstaculos = graph_gen.criar_obstaculos(fonte=fonte, destino=destino, num=num_onstaculos)
    # graph_gen.plot()

    """Inicializando as memórias de relações e obstáculos"""
    top.inicializar_mem(graph_gen.graph, obstaculos=obstaculos)

    """Calculando o menor caminho"""
    menor_caminho = top.calcular_caminho(fonte=fonte, destino=destino)

    custo = graph_gen.graph.get_custo_caminho(menor_caminho)
    if grafico:
        graph_gen.plot_path_obstaculo(menor_caminho, (lista_obstaculos_plot(top.mem_obstaculos)))
    return menor_caminho, custo


def lista_obstaculos_plot(obstaculos):
    list_obstaculos = []
    list_obstaculos_nodes = []

    for endereco, posicao in obstaculos.mem.items():
        for vizinho in posicao:
            if vizinho[1]:
                list_obstaculos.append((endereco, vizinho[0]))
                list_obstaculos_nodes.append(vizinho[0])
    list_obstaculos_nodes = set(list_obstaculos_nodes)
    return list_obstaculos, list_obstaculos_nodes


if __name__ == '__main__':
    teste = False
    grafico = True
    # teste = True
    # grafico = False
    num_nos = 33
    inicio = 30
    tem_obstaculo = True
    # tem_obstaculo = False

    if not teste:
        inicio = num_nos - 1

    for idx in range(inicio, num_nos):
        num_onstaculos = 0
        if tem_obstaculo:
            num_onstaculos = idx/4
            # num_onstaculos = 0
        caminho, custo = main(num_nos=idx, debug=False, grafico=grafico, num_onstaculos=num_onstaculos)
        caminho2, custo2 = main_sequencial(num_nos=idx, debug=False, grafico=grafico, num_onstaculos=num_onstaculos)

        # print(f"Num de nós {idx}")
        # print(f"Referência {caminho2, custo2}")
        # print(f"Modelo {caminho, custo}")

        # if custo != custo2 or caminho2 != caminho:
        if custo != custo2:
            warnings.warn(f"Foram encontrados erros: num de nós {idx}")
            print(f"Referência {caminho2, custo2}")
            print(f"Modelo {caminho, custo}")
            break

        else:
            print(f"Passou {idx}!")
    # print(f"Passou Tudo!")
