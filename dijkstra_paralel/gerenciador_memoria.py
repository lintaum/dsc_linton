import numpy as np


class Memoria():
    """Modelo base de uma memória genérica"""
    def __init__(self, linhas, colunas):
        self.mem = {}

    def ler(self, endereco):
        return list(self.mem[endereco],)

    def escrever(self, endereco, valor):
        self.mem[endereco] = valor


class MemoriaInt():
    """Modelo base de uma memória genérica"""
    def __init__(self, linhas, colunas):
        self.mem = {}

    def ler(self, endereco):
        return self.mem[endereco]

    def escrever(self, endereco, valor):
        self.mem[endereco] = valor

if __name__ == '__main__':
    mem_250_320 = Memoria(10, 4)
    print("Criada")