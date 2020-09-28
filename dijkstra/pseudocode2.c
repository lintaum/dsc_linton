void Graph: : dijkstra(Fonte s , Nós N)
{
    
    for n in N: %para cada Vertice n em N
        if(n is not s){
            L[n] = w(s,n)    
    s.distancia = 0;
    T = {s}
    enquanto(T for diferente de N)
    {
        Vertice v = vertice com a menor distância L[x] e que não faz parte de T;
        para cada Vertice w vizinho a v{
            se(w está em T) // se w já foi analizado
            {
                se(L[v] + w(v,w) < L[w])
                {
                    // caso o novo caminho seja menor, atualiza w
                    L[w] = L[v] + w(v,w);
                    w.caminho = v;
                }
            }
            T.adicionar(w)
        }
    }
}

