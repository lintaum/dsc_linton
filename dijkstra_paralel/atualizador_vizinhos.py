

class AtualizadorVizinhos():
    """
    calcula e atualiza a distância entre o nó e a fonte
        tent(w) = min {tent(w), tent(v) + c(v,w)}.
    """
    @staticmethod
    def atualizar(
            endereco_w,
            custo_vw,
            endereco_v,
            distancia_w,
            distancia_v,
            # custo_menor_vizinho_w
    ):

        atualizou = False
        anterior = False
        distancia_vw = distancia_v + custo_vw
        # Se distancia a partir do vizinho é menor, atualiza
        if distancia_vw < distancia_w:
            atualizou = True
            anterior = endereco_v

        return atualizou, anterior, distancia_vw, endereco_w





