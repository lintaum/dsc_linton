inf = float('inf')
def criar_analise(model):
    # Resultados out

    count_out = 0
    total_out = 0
    max_out = 0
    min_out = inf
    for aprovados_out in model.total_aprovados_out:
        total = len(aprovados_out)
        total_out += total
        count_out+= 1
        if total > max_out:
            max_out = total

        if total < min_out:
            min_out = total

    media_out = total_out / count_out

    print(f"Máximo de nós ativos simultaneamente: {max(model.total_empilhados)}")
    print(f"Resultados OUT: Média={round(media_out)}; Máximo={max_out}")