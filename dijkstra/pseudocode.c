
struct Vertice
{
    List adj; // Lista de adjacência
    bool conhecido; 
    Inteiro distancia; 
    Vertice caminho; // Provavelmente Vertice *
    // Outros dados ou funções
}

void Graph: : dijkstra(Vertice fonte )
{
    para cada Vertice v
    {
        v.distancia = INFINITO;
        v.conhecido = FALSO;
    }
    fonte.distancia = 0;
    enquanto(existir um vertice com distancia desconhecida)
    {
        Vertice v = vertice com a menor distância desconhecida;
        v.conhecido = VERDADEIRO;
        para cada Vertice w vizinho a v
            se(!w.conhecido)
            {
                DistType cvw = custo do arco de v para w
                se(v.distancia + cvw < w.distancia)
                {
                    // atualiza w
                    diminua(w.distancia para v.distancia + cvw);
                    w.caminho = v;
                }
            }
    }
}
