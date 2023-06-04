#include <stdio.h>
#include <stdlib.h>

#define MEM_RELACOES (int *) 0x30000
#define MEM_OBSTACULOS (int *) 0x38000
#define MEM_RESULTADO (int *) 0x3B000
// Número máximo de nós no grafo
#define MAX_NODES 7

// Número máximo de relações por nó
#define MAX_RELATIONS 8

int fonte = 0;
int destino = 6;
int INT_MAXIMO = 2147483647;
// Estrutura de um nó
typedef struct Node {
    int value;
    int distance;
    int visited;
    struct Node* parent;
    struct Node* relations[MAX_RELATIONS];
    int weights[MAX_RELATIONS];
} Node;

// Função para criar um novo nó
Node* createNode(int value) {
    Node* node = (Node*)malloc(sizeof(Node));
    node->value = value;
    node->distance = INT_MAXIMO;
    node->visited = 0;
    node->parent = NULL;
    for (int i = 0; i < MAX_RELATIONS; i++) {
        node->relations[i] = NULL;
        node->weights[i] = 0;
    }
    return node;
}

// Função para adicionar uma relação entre dois nós
void addRelation(Node* node1, Node* node2, int weight) {
    int i = 0;
    while (node1->relations[i] != NULL && i < MAX_RELATIONS) {
        i++;
    }
    if (i < MAX_RELATIONS) {
        node1->relations[i] = node2;
        node1->weights[i] = weight;
    }
}

// Função para encontrar o nó com a menor distância não visitada
Node* findMinDistanceNode(Node* nodes[MAX_NODES], int numNodes) {
    int minDistance = INT_MAXIMO;
    Node* minNode = NULL;
    for (int i = 0; i < numNodes; i++) {
        if (!nodes[i]->visited && nodes[i]->distance < minDistance) {
            minDistance = nodes[i]->distance;
            minNode = nodes[i];
        }
    }
    return minNode;
}

// Função para imprimir o menor caminho de um nó até o nó de origem
void printPath(Node* node) {
    if (node->parent != NULL) {
        printPath(node->parent);
    }

    printf("%d ", node->value);
//    *MEM_RESULTADO = node->value;
}

// Função para calcular o menor caminho entre dois nós usando o algoritmo de Dijkstra
void dijkstra(Node* nodes[MAX_NODES], int numNodes, int startNodeValue, int endNodeValue) {
    Node* startNode = NULL;
    Node* endNode = NULL;

    // Encontra os nós de origem e destino
    for (int i = 0; i < numNodes; i++) {
        if (nodes[i]->value == startNodeValue) {
            startNode = nodes[i];
        }
        if (nodes[i]->value == endNodeValue) {
            endNode = nodes[i];
        }
    }



    if (startNode == NULL || endNode == NULL) {
        printf("Nos de origem ou destino não encontrados.\n");
        return;
    }
    else{
		printf("Nos de origem ou destino encontrados.\n");
	}

    // Inicializa a distância do nó de origem como 0
    startNode->distance = 0;

    // Encontra o menor caminho
    for (int i = 0; i < numNodes; i++) {
        Node* currentNode = findMinDistanceNode(nodes, numNodes);
        currentNode->visited = 1;
        // Atualiza as distâncias dos nós adjacentes não visitados
        for (int j = 0; j < MAX_RELATIONS; j++) {
            Node* neighbor = currentNode->relations[j];
            if (neighbor != NULL && !neighbor->visited) {
                int distance = currentNode->distance + currentNode->weights[j];
                if (distance < neighbor->distance) {
                    neighbor->distance = distance;
                    neighbor->parent = currentNode;
                }
            }
        }
    }

    // Imprime o menor caminho
    printf("Menor caminho entre %d e %d: ", startNodeValue, endNodeValue);
    printPath(endNode);
    *MEM_RESULTADO = 10;
//    printf("\n");
}

int main() {
    // Criação dos nós do grafo
    Node* nodes[MAX_NODES];
    for (int i = 0; i < MAX_NODES; i++) {
        nodes[i] = createNode(i);
//        *MEM_RESULTADO = i;
//        printf("Criando no %d\n", i);
    }
    //*MEM_RESULTADO = 1;

    // Adição das relações entre os nós (exemplo)
    addRelation(nodes[0], nodes[1], 3);



    // Chama a função Dijkstra para calcular o menor caminho
    dijkstra(nodes, MAX_NODES, fonte, destino);



    // Libera a memória alocada para os nós
    for (int i = 0; i < MAX_NODES; i++) {
        free(nodes[i]);
    }

    return 0;
}

