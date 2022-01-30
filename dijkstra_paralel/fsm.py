class FSM():
    IDLE = 0
    INICIALIZAR = 1
    AGUARDANDO = 2
    FORMAR_CAMINHO = 3
    FINALIZAR = 4

    def __init__(self):
        self.state = self.IDLE

    def next_state(self):
        if self.state == self.FINALIZAR:
            self.state = self.IDLE
            return self.state
        self.state += 1