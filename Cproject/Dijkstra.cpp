#include <stdio.h>
#include <stdlib.h>
#define MEM_RELACOES (int *) 0x30000
#define MEM_OBSTACULOS (int *) 0x38000
#define MEM_RESULTADO (int *) 0x3B000

// N�mero m�ximo de rela��es por n�
#define MAX_RELATIONS 8
// N�mero m�ximo de n�s no grafo
#define MAX_NODES 1023
// N�mero m�ximo de n�s no grafo
#define CUSTO_WIDTH 4

int SIM = 1;
unsigned int array[MAX_NODES*8];
unsigned int array_obstaculos[MAX_NODES];
unsigned int resultado;
//unsigned int * array = MEM_RELACOES;
//unsigned int * resultado = MEM_RESULTADO;

int INT_MAXIMO = 2147483647;
// Estrutura de um n�
typedef struct Node {
    unsigned int value;
    int distance;
    int visited;
    struct Node* parent;
    struct Node* relations[MAX_RELATIONS];
    int weights[MAX_RELATIONS];
} Node;


// Fun��o para criar um novo n�
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

// Fun��o para adicionar uma rela��o entre dois n�s
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

// Fun��o para encontrar o n� com a menor dist�ncia n�o visitada
Node* findMinDistanceNode(Node* nodes[MAX_NODES], int numNodes) {
    int minDistance = INT_MAXIMO;
    Node* minNode = NULL;
//  Todo: Est� muito lento assim, n�o � necess�rio analisar todos os n�s, as solu��es que testei at� agora pioram o desempenho
    for (int i = 0; i < numNodes; i++) {
        if (!nodes[i]->visited && nodes[i]->distance < minDistance) {
            minDistance = nodes[i]->distance;
            minNode = nodes[i];
        }
    }
    return minNode;
}

// Fun��o para imprimir o menor caminho de um n� at� o n� de origem
void printPath(Node* node) {
    if (node->parent != NULL) {
        printPath(node->parent);
    }

	printf("%d ", node->value);
    //resultado[0] = node->value;
}

// Fun��o para calcular o menor caminho entre dois n�s usando o algoritmo de Dijkstra
void dijkstra(Node* nodes[MAX_NODES], int numNodes, unsigned int startNodeValue, unsigned int endNodeValue) {
    Node* startNode = NULL;
    Node* endNode = NULL;
	
	// printf("\Procurando os nos de origem e destino...\n");    
	
	startNode = nodes[startNodeValue];
	endNode = nodes[endNodeValue]; 

    // Inicializa a dist�ncia do n� de origem como 0
    startNode->distance = 0;

    // Encontra o menor caminho
    for (int i = 0; i < numNodes; i++) {
        Node* currentNode = findMinDistanceNode(nodes, numNodes);
        currentNode->visited = 1;
        //printf("\nNo: %d", currentNode->value);
        // Atualiza as dist�ncias dos n�s adjacentes n�o visitados
        for (int j = 0; j < MAX_RELATIONS; j++) {
        	Node* neighbor = currentNode->relations[j];
        	if (neighbor != NULL && !neighbor->visited) {
        		
				//Verificando se o n� � um obst�culo
        		if (array_obstaculos[neighbor->value] == 0){
        			
		            int distance = currentNode->distance + currentNode->weights[j];
		            if (distance < neighbor->distance) {
		                neighbor->distance = distance;
		                neighbor->parent = currentNode;
		            }
	            }
	            else{
	            	// Quando for obstaculo e n�o tiver sido visitado ainda, marca como visitado e incrementa o contador
	            	if (neighbor->visited == 0){
	            		neighbor->visited = 1;
	            		i = i + 1;
					}
				}
			}
        	
            
        }
    }
//	printf("\nMenor caminho calculado...\n");
    // Imprime o menor caminho
    printPath(endNode);
}

void splitInt(unsigned int num, unsigned int* vizinho, unsigned int* custo) {
	*vizinho = num >> CUSTO_WIDTH;
	*custo = num & ((1 << CUSTO_WIDTH) - 1);
//	printf("%d\t%d\t%d\t", num, (int)vizinho, (int)custo);
}

int montar_vetor() {
	//	Deve ser rodado apenas na simula��o do Dev C++	
    FILE *file;    
    unsigned int i, num;

    // Abre o arquivo para leitura
    file = fopen("../ProjetosPycharm/dsc_linton/mem_relacoes.txt", "r");

    if (file == NULL) {
        // printf("Erro ao abrir o arquivo.\n");
        return 1;
    }
 
    // L� os inteiros do arquivo e os armazena no vetor
    for (i = 0; i < (MAX_NODES)*8; i++) {
        if (fscanf(file, "%d", &num) != 1) {
            // printf("Erro ao ler o inteiro %d do arquivo.\n", i + 1);
            fclose(file);
            return 1;
        }
       //printf("%d\t", i);
        array[i] = num;
    }

    // Fecha o arquivo
    fclose(file);

    // Imprime os inteiros armazenados no vetor
    //for (i = 0; i < MAX_NODES; i++) {
    	// printf("NO %d:\t", i);
    	//for (int w=0; w<MAX_RELATIONS;w++)
        	// printf("%d\t", array[i*MAX_RELATIONS+w]);
		// printf("\n");        	
    //}
    // printf("\nNumero de nos lidos no arquivo %d\n", i);

    return 0;
}

int montar_vetor_obstaculos() {
	//	Deve ser rodado apenas na simula��o do Dev C++	
    FILE *file2;    
    unsigned int i, num;

    // Abre o arquivo para leitura
    file2 = fopen("../ProjetosPycharm/dsc_linton/mem_obstaculo.txt", "r");

    if (file2 == NULL) {
        printf("Erro ao abrir o arquivo.\n");
        return 1;
    }
 
    // L� os inteiros do arquivo e os armazena no vetor
    for (i = 0; i < MAX_NODES; i++) {
        if (fscanf(file2, "%d", &num) != 1) {
            // printf("Erro ao ler o inteiro %d do arquivo.\n", i + 1);
            fclose(file2);
            return 1;
        }
       //printf("%d\t", i);
        array_obstaculos[i] = num;
    }

    // Fecha o arquivo
    fclose(file2);

    // Imprime os inteiros armazenados no vetor
//    for (i = 0; i < MAX_NODES; i++) {
//    	printf("NO %d:\t Obstaculo %d\n", i, array_obstaculos[i]);
//    }
//    printf("\nNumero de nos lidos no arquivo %d\n", i);

    return 0;
}

int adicionar_relacoes() {
    // Imprime os inteiros armazenados no vetor
    unsigned int vizinho, custo;
    unsigned int vizinho_int;
    Node* nodes[MAX_NODES];
    
//    Inicializando o grafo com os n�s vazios
    for (unsigned int i = 0; i < MAX_NODES; i++) {
        nodes[i] = createNode(i);
        // printf("Criado no %d %d\n", i, nodes[i]->value);
    }
    // printf("\nGrafo criado...\n");
    
    for (unsigned int i = 0; i < MAX_NODES; i++) {
    	// printf("NO %d:\n", i);
    	for (unsigned int w=0; w<MAX_RELATIONS;w++){
    		splitInt(array[i*MAX_RELATIONS+w], &vizinho, &custo);
    		
//    			TODO: Colocar Valor m�ximo de custo
    		if (custo < 15){
    			//printf("\tbase: %d\tvizinho: %d\tcusto: %d\n", array[i*MAX_RELATIONS+w], vizinho, custo);
				// printf("\n\t addRelation base: %d\tvizinho: %d\tcusto: %d", nodes[i]->value, nodes[vizinho]->value, custo);
				addRelation(nodes[i], nodes[vizinho], custo);
			}
		}
		// printf("\n");        	
    }
    return 0;
}

int main() {
	
	//monta um vetor com a memoria de rela��o a partir de um arquivo, para simular a mem�ria do FPGA
	montar_vetor();
	montar_vetor_obstaculos();
		
	// printf("\nVetor montado...\n");    
	// Imprime os inteiros armazenados no vetor
    unsigned int vizinho, custo;
    unsigned int vizinho_int;
    Node* nodes[MAX_NODES];
    
//    Inicializando o grafo com os n�s vazios
    for (unsigned int i = 0; i < MAX_NODES; i++) {
        nodes[i] = createNode(i);
        // printf("Criado no %d %d\n", i, nodes[i]->value);
    }
    // printf("\nGrafo criado...\n");
    
//    Incluindo as relacoes dos nos
    for (unsigned int i = 0; i < MAX_NODES; i++) {
    	// printf("NO %d:\n", i);
    	for (unsigned int w=0; w<MAX_RELATIONS;w++){
    		splitInt(array[i*MAX_RELATIONS+w], &vizinho, &custo);
//    		TODO: Colocar Valor m�ximo de custo
    		if (custo < 15){
    			//printf("\tbase: %d\tvizinho: %d\tcusto: %d\n", array[i*MAX_RELATIONS+w], vizinho, custo);
				// printf("\n\t addRelation base: %d\tvizinho: %d\tcusto: %d", nodes[i]->value, nodes[vizinho]->value, custo);
				addRelation(nodes[i], nodes[vizinho], custo);
			}
		}
		// printf("\n");        	
    }
	// printf("\nRelacoes adicionadas...\n");    
	
    // Chama a fun��o Dijkstra para calcular o menor caminho
   //printf("Fonte %d Destino %d", 0, destino);

    dijkstra(nodes, MAX_NODES, 0, MAX_NODES-1);

    // Libera a mem�ria alocada para os n�s
    for (unsigned int i = 0; i < MAX_NODES; i++) {
        free(nodes[i]);
    }

    return 0;
}




