def simular_vivado():
    # /home/linton/proj_dsc/vivado/sim/xsim
    import subprocess
    # subprocess.run(["sim_top_tb"])
    import os

    os.system("cd /home/linton/proj_dsc/vivado/sim/xsim;./top_tb.sh > sim_log.log")

    texto_aprovado = "Distância Aprovada"
    file = open("/home/linton/proj_dsc/vivado/sim/xsim/sim_log.log", "r")
    for linha in file:
        # print(linha)
        if texto_aprovado in linha:
            # print("Passou na simulação!")
            return True
    return False

if __name__ == '__main__':
    simular_vivado()