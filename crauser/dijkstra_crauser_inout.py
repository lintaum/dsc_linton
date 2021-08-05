import time
from crauser.random_graph import GraphGen
from multiprocessing import Process, Array
inf = float('inf')


def update_tent(no_v, no_w, empilhados, distancia, anterior, custo_vizinho):
    """
    calcula a distância entre o nó e a fonte
        tent(w) = min {tent(w), tent(v) + c(v,w)}.
    """
    """Marca o nó como empilhado"""
    atualizou = False
    # Distância a partir do vizinho
    dist_vw = custo_vizinho + distancia[no_v]
    # Se distancia a partir do vizinho é menor, atualiza
    if dist_vw < distancia[no_w]:
        atualizou = True
        anterior[no_w] = no_v
        distancia[no_w] = dist_vw

    return atualizou, no_v, dist_vw


def remover_no(no, vizinhos, empilhado_vizinhos, distancia_vizinhos, anterior_vizinhos, custo_vizinho, return_dict):
    """Empilhando os vizinhos do no e calculando o tent deles"""

    result_vizinho = []
    for no_vizinho in vizinhos:
        """Se ainda não foi estabelecido, inicializar ou atualizar"""
        atualizou, anterior, distancia = update_tent(no, no_vizinho, empilhado_vizinhos, distancia_vizinhos, anterior_vizinhos, custo_vizinho[no_vizinho])
        result_vizinho.append([no_vizinho, atualizou, anterior, distancia])

    return_dict[no] = result_vizinho
    return distancia_vizinhos, anterior_vizinhos

def remover_no_aprovado(grafo, aprovado, estabelecidos, distancia, anterior, result):
    vizinhos = grafo.get_relacoes_vizinhos(aprovado)
    distancia_vizinhos = {}
    empilhado_vizinhos = []
    anterior_vizinhos = {}
    custo_vizinho = {}
    vizinhos_validados = []

    for no, vizinho in vizinhos:
        """Se o vizinho já foi estabelecido, já achou o menor caminho então não faz nada"""
        if not estabelecidos[vizinho] == 1:
            # vai ser alterado
            distancia_vizinhos[vizinho] = distancia[vizinho]
            anterior_vizinhos[vizinho] = anterior[vizinho]

            empilhado_vizinhos.append(vizinho)
            custo_vizinho[vizinho] = grafo.get_custo(no, vizinho)
            vizinhos_validados.append(vizinho)

    distancia_vizinhos[no] = distancia[no]

    remover_no(no, vizinhos_validados, empilhado_vizinhos, distancia_vizinhos, anterior_vizinhos, custo_vizinho, result)


class DijkstraCrauser:
    """"
        O menor caminho é formado por todos os menores caminhos do caminho entre a fonte e o destino.
        Dessa forma, para cada nó basta saber qual o nó anterior na direção da fonte para se descobrir,
        o menor caminho.
    """
    def __init__(self, fonte, destino, grafo):
        self.total_aprovados_in = []
        self.total_aprovados_out = []
        self.fonte = fonte
        self.destino = destino
        self.grafo = grafo
        self.menor_dist = {}
        self.criterio_out = {}
        self.criterio_in = {}
        # self.treshold_out = inf
        # Memoria Compartilhada
        # self.estabelecidos = Array("i", self.grafo.nos)
        # self.empilhados = Array("i", self.grafo.nos)
        # self.distancia = Array("i", self.grafo.nos)
        # self.anterior = Array("i", self.grafo.nos)

        self.estabelecidos = {i:0 for i in range(0, len(self.grafo.nos))}
        self.empilhados = {i:0 for i in range(0, len(self.grafo.nos))}
        self.empilhados = []
        self.distancia = {i:100000 for i in range(0, len(self.grafo.nos))}
        self.anterior = {i:0 for i in range(0, len(self.grafo.nos))}
        self.inicializar()

    def inicializar(self):
        self.anterior[self.fonte] = 0
        self.empilhados.append(self.fonte)
        self.criterio_in[self.fonte] = 0
        for no in range(len(self.grafo.nos)):
            self.estabelecidos[no] = 0
            # self.empilhados[no] = 0
            self.distancia[no] = 100000000
            self.menor_dist[no] = 100

        self.distancia[self.fonte] = 0

    def get_menor_caminho(self):
        """Coletando o menor caminho, lendo do destino até a fonte"""
        menor_caminho = [self.destino]
        no = self.destino
        while no is not self.fonte:
            anterior = self.anterior[no]
            menor_caminho.append(anterior)
            no = anterior
            # print(f"Construindo menor Caminho: {menor_caminho}")

        # Invertendo a ordem da lista
        menor_caminho = menor_caminho[::-1]

        return menor_caminho

    def update_criterio_out(self):
        """o(v) = tent(v) + min{c(v, u) : (v, u) E E} """
        for no in self.grafo.nos:
            if no in self.empilhados:
                self.criterio_out[no] = self.distancia[no] + self.grafo.get_menor_vizinho(no)

    def update_treshold_out(self):
        """L = min{tent(u) + c(u, z) : u is queued and (u, z) E E} """
        treshold_out = inf
        for no in self.empilhados:
            treshold_no = self.distancia[no] + self.grafo.get_menor_vizinho(no)
            if treshold_no < treshold_out:
                treshold_out = treshold_no
        return treshold_out

    def get_aprovados_out(self):
        """O nó pode ser removido quando a distância dele até a fonte não pode ser menor"""
        self.update_criterio_out()
        treshold_out = self.update_treshold_out()
        aprovados = []
        for no in self.empilhados:
            if self.distancia[no] <= treshold_out:
                aprovados.append(no)
        return aprovados

    def update_criterio_in(self):
        """ i(v) = tent(v) - min{c(u,v) : (u,v) E E}  """
        for no in self.empilhados:
            self.criterio_in[no] = self.distancia[no] - self.grafo.get_menor_vizinho_in(no)

    def update_treshold_in(self):
        """M = min {tent(u) : u is queued} """
        self.menor_dist = inf
        for no in self.empilhados:
            if self.distancia[no] < self.menor_dist:
                self.menor_dist = self.distancia[no]

    def get_aprovados_in(self):
        """i(v) <= M"""
        self.update_criterio_in()
        self.update_treshold_in()
        aprovados = []
        for no in self.empilhados:
            if self.criterio_in[no] <= self.menor_dist:
                aprovados.append(no)
        return aprovados

    def tem_empilhado(self):
        if len(self.empilhados) > 0:
            return True
        return False

    def tem_sem_estabelecer(self):
        for no in self.grafo.nos:
            if self.estabelecidos[no] == 1:
                return True
        return False

    def criar_analise(self):
        # Resultados IN
        count_in = 0
        total_in = 0
        max_in = 0
        min_in = inf
        for aprovados_in in self.total_aprovados_in:
            total = len(aprovados_in)
            total_in += total
            count_in+= 1
            if total > max_in:
                max_in = total

            if total < min_in:
                min_in = total

        media_in = total_in / count_in

        # Resultados out
        count_out = 0
        total_out = 0
        max_out = 0
        min_out = inf
        for aprovados_out in self.total_aprovados_out:
            total = len(aprovados_out)
            total_out += total
            count_out+= 1
            if total > max_out:
                max_out = total

            if total < min_out:
                min_out = total

        media_out = total_out / count_out

        num_in_dentro = 0
        num_out_dentro = 0
        num_distintos = 0
        num_iguais = 0
        num_diff = 0
        for idx in range(len(self.total_aprovados_out)):

            aprovados_in = self.total_aprovados_in[idx]
            aprovados_out = self.total_aprovados_out[idx]
            distintos = set(aprovados_in).isdisjoint(aprovados_out)
            in_dentro = set(aprovados_in).issubset(aprovados_out)
            out_dentro = set(aprovados_out).issubset(aprovados_in)


            if distintos:
                num_distintos += 1
            elif set(aprovados_out) == set(aprovados_in):
                num_iguais += 1
            else:
                if in_dentro:
                    num_in_dentro += 1
                else:
                    if out_dentro:
                        num_out_dentro += 1
                    else:
                        num_diff += 1

        print(f"Vezes que o IN e OUT foram distintos: {num_distintos}")
        print(f"Vezes que o IN e OUT foram iguais: {num_iguais}")
        print(f"Vezes que o IN estava contido no OUT: {num_in_dentro}")
        print(f"Vezes que o OUT estava contido no IN: {num_out_dentro}")
        print(f"Vezes que o OUT e IN ambos possuiam pelo menos 1 elemento diferentes: {num_diff}")
        print(f"Resultados IN: Média={round(media_in)}; Mínimo={min_in}; Máximo={max_in}")
        print(f"Resultados OUT: Média={round(media_out)}; Mínimo={min_out}; Máximo={max_out}")

    def dijkstra(self, paralelo=True, debug=False):
        count = 0
        import multiprocessing
        manager = multiprocessing.Manager()
        jobs = []

        while self.tem_empilhado():
            # print(f"Aprovados {self.get_aprovados_out()}")
            count += 1
            """Coletando os nós que podem ser removidos (dist=tent) em paralelo"""
            aprovados_in = self.get_aprovados_in()
            aprovados_out = self.get_aprovados_out()
            aprovados = set(aprovados_in + aprovados_out)
            # aprovados = aprovados_out
            # aprovados = aprovados_in
            # if debug:
                # print(f"Aprovados IN {len(aprovados_in)}: {aprovados_in}")
                # print(f"Aprovados OUT {len(aprovados_out)}: {aprovados_out}")
                # self.total_aprovados_in.append(aprovados_in)
                # self.total_aprovados_out.append(aprovados_out)

            if paralelo:
                result = manager.dict()
            else:
                result = {}

            process = []
            for aprovado in aprovados:
                # remover_no_aprovado(self.grafo, aprovado, self.estabelecidos, self.distancia, self.anterior, result)

                if paralelo:
                    p = multiprocessing.Process(target=remover_no_aprovado, args=(self.grafo, aprovado, self.estabelecidos, self.distancia, self.anterior, result))
                    jobs.append(p)
                    p.start()
                    # p.join()
                    process.append(p)
                else:
                    remover_no_aprovado(self.grafo, aprovado, self.estabelecidos, self.distancia, self.anterior, result)

            for p in process:
                p.join()

            """Estabelecendo o nó já visitado, removendo dos empilhados e recuperando dados dos buffers"""
            for aprovado in aprovados:
                self.empilhados.remove(aprovado)
                self.estabelecidos[aprovado] = 1

                for vizinho, atualizou, anterior, distancia in result[aprovado]:
                    if atualizou:
                        if distancia < self.distancia[vizinho]:
                            self.distancia[vizinho] = distancia
                            self.anterior[vizinho] = anterior

                    if (vizinho not in self.empilhados) and self.estabelecidos[vizinho]==0:
                        self.empilhados.append(vizinho)
        if debug:
            print(f"\nTotal de iterações: {count}")
            # self.criar_analise()
        return self.get_menor_caminho()


def main(num_nos=120, debug=False, grafico=False):
    tempo_objetivo = 425 * 0.000001
    # Gerando o grafo e plotando

    # do stuff
    no_inicio = 0
    no_destino = num_nos-1
    graph_gen = GraphGen(max_weigth=10)
    graph_gen.adjacent_lis(nodes=num_nos)
    # graph_gen.plot()

    # Calculando o menor caminho

    start = time.time()
    menor_caminho_p = DijkstraCrauser(no_inicio, no_destino, graph_gen.graph).dijkstra(paralelo=True, debug=debug)
    end = time.time()
    tempo = end - start
    custo_p = graph_gen.graph.get_custo_caminho(menor_caminho_p)
    if debug:
        print(f"Tempo Paralelo: {round(tempo,2)}s | Fator Objetivo: {round(tempo/tempo_objetivo)}")

    menor_caminho = menor_caminho_p

    start = time.time()
    menor_caminho_s = DijkstraCrauser(no_inicio, no_destino, graph_gen.graph).dijkstra(paralelo=False, debug=debug)
    end = time.time()
    tempo = end - start
    custo_s = graph_gen.graph.get_custo_caminho(menor_caminho_s)
    if debug:
        print(f"Tempo Sequencial: {round(tempo,2)}s | Fator Objetivo: {round(tempo/tempo_objetivo)}")

    menor_caminho = menor_caminho_s

    if custo_s != custo_p:
        print("\nResultado sequencial e paralelo diferente")
        import sys
        sys.exit()

    custo = graph_gen.graph.get_custo_caminho(menor_caminho)
    if debug:
        print(f"Custo do caminho: {custo}")
    if grafico:
        graph_gen.plot_path(menor_caminho)

    return menor_caminho, custo


if __name__ == '__main__':
    from dijkstra.dijkstra_crauser import main as main_crauser
    num_nos = 1024
    debug = True
    grafico = False
    if debug:
        caminho1, custo1 = main(num_nos=num_nos, debug=debug, grafico=grafico)
        caminho2, custo2 = main_crauser(num_nos=num_nos, debug=debug, grafico=grafico)

        if custo2 != custo1:
                print(f"Num nós {num_nos}")
                print(f"Custo Out {custo1}")
                print(f"Custo Ref {custo2}")
                print(f"Caminho Out {caminho1}")
                print(f"Caminho Ref {caminho2}")
                import sys
                sys.exit()
        else:
            print(f"Passou {num_nos}")
    else:
        erro = 0
        for n in range(5, 1024):
            num_nos = n
            caminho1, custo1 = main(num_nos=num_nos, debug=debug,)
            caminho2, custo2 = main_crauser(num_nos=num_nos, debug=debug)

            if custo2 != custo1:
                erro += 1
                print(f"Num nós {num_nos}")
                print(f"Custo Out {custo1}")
                print(f"Custo Ref {custo2}")
                print(f"Caminho Out {caminho1}")
                print(f"Caminho Ref {caminho2}")
                import sys
                sys.exit()
            else:
                print(f"Passou {num_nos}")

        if erro > 0:
            print(f"Foram encontrados {erro} erros")
