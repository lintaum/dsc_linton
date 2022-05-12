class FormadorCaminho():
    @staticmethod
    def gerar_caminho(fonte, destino, mem_anterior):
        """Coletando o menor caminho, lendo do destino até a fonte"""
        menor_caminho = [destino]
        no = destino
        while no is not fonte:
            anterior = mem_anterior.ler(no)
            if anterior is not None:
                menor_caminho.append(anterior)
                no = anterior
            else:
                break
            # print(f"Construindo menor Caminho: {menor_caminho}")
        # Invertendo a ordem da lista
        menor_caminho = menor_caminho[::-1]

        return menor_caminho