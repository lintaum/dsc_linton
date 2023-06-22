def round_to_bin(data, max_bits):
    """Verifica se um determinado valor pode ser armazenado em uma determinada quantidade de bit, caso contratio, retorna
    o maior valor possível"""
    max_value = pow(2, max_bits) - 1
    if data > max_value:
        return max_value
    return data


def dict_2_vmem(dict_mem,
                obstaculos,
                max_bits_relacao=10,
                max_bits_custo=4,
                nome_arquivo_relacao="../mem_relacoes.bin",
                nome_arquivo_obstaculo="../mem_obstaculo.bin",
                max_relacoes=8):
    """Converte uma memória em python para o formato de importação verilog"""
    relacao_str = ''
    obstaculo_str = ''

    for endereco, linha in dict_mem.mem.items():
        """
            {} places a variable into a string
            0 takes the variable at argument position 0
            : adds formatting options for this variable (otherwise it would represent decimal 6)
            08 formats the number to eight digits zero-padded on the left
            b converts the number to its binary representation
        """
        linha_relacao = ""
        for relacao, obstaculo, custo in linha:
            relacao_bin = ('{0:0' + f"{max_bits_relacao}" + 'b}').format(round_to_bin(relacao, max_bits_relacao))
            custo_bin = ('{0:0' + f"{max_bits_custo}" + 'b}').format(round_to_bin(custo, max_bits_custo))

            if len(relacao_bin) > max_bits_relacao or len(custo_bin) > max_bits_custo:
                break
            relacao_str = relacao_str + relacao_bin + custo_bin
            # relacao_str = relacao_str + f"R{relacao}C{custo}"
            # relacao_str = relacao_str + f"C{custo}"

        for idx in range((max_relacoes-len(linha))):
            for idx2 in range(max_bits_relacao+max_bits_custo):
                relacao_str = relacao_str + "1"

        relacao_str = relacao_str + "\n"

        if endereco in obstaculos:
            obstaculo_str = obstaculo_str + "1\n"
        else:
            obstaculo_str = obstaculo_str + "0\n"

    text_file = open(nome_arquivo_relacao, "w")
    text_file.write(relacao_str)
    text_file.close()

    text_file = open(nome_arquivo_obstaculo, "w")
    text_file.write(obstaculo_str)
    text_file.close()


def dict_2_mif(dict_mem,
                obstaculos,
                max_bits_relacao=10,
                max_bits_custo=4,
                nome_arquivo_relacao="../mem_relacoes.mif",
                nome_arquivo_obstaculo="../mem_obstaculo.mif",
                max_relacoes=8):

    """Converte uma memória em python para o formato mif do quartus"""
    num_nos = len(dict_mem.mem)
    relacao_str = f'WIDTH=32;\nDEPTH=16384;\nADDRESS_RADIX=UNS;\nDATA_RADIX=UNS;\nCONTENT BEGIN\n'
    obstaculo_str = f'WIDTH=32;\nDEPTH=2048;\nADDRESS_RADIX=UNS;\nDATA_RADIX=UNS;\nCONTENT BEGIN\n'
    count_addr = 0
    count_addr_obstaculo = 0
    valor_maximo_bin = ''
    for idx2 in range(max_bits_relacao + max_bits_custo):
        valor_maximo_bin = valor_maximo_bin + "1"
    valor_maximo_int = int(valor_maximo_bin, 2)
    for endereco, linha in dict_mem.mem.items():
        """
            {} places a variable into a string
            0 takes the variable at argument position 0
            : adds formatting options for this variable (otherwise it would represent decimal 6)
            08 formats the number to eight digits zero-padded on the left
            b converts the number to its binary representation
        """
        linha_relacao = ""
        count_vizinho = 0
        # relacao_str = relacao_str + f'\tNo - {(count_addr)/8}\n'
        for relacao, obstaculo, custo in linha:
            relacao_bin = ('{0:0' + f"{max_bits_relacao}" + 'b}').format(round_to_bin(relacao, max_bits_relacao))
            custo_bin = ('{0:0' + f"{max_bits_custo}" + 'b}').format(round_to_bin(custo, max_bits_custo))
            relacao_custo_bin = relacao_bin + custo_bin
            # relacao_custo_bin = relacao_bin
            relacao_custo_int = int(relacao_custo_bin, 2)
            if len(relacao_bin) > max_bits_relacao or len(custo_bin) > max_bits_custo:
                break
            relacao_str = relacao_str + f'{count_addr}\t:{relacao_custo_int};\n'
            count_addr=count_addr+1
            count_vizinho = count_vizinho + 1


        for idx in range(max_relacoes-count_vizinho):
            relacao_str = relacao_str + f'{count_addr}\t:{valor_maximo_int};\n'
            count_addr = count_addr + 1

        if endereco in obstaculos:
            obstaculo_str = obstaculo_str + f'{count_addr_obstaculo}\t:{1};\n'
        else:
            obstaculo_str = obstaculo_str + f'{count_addr_obstaculo}\t:{0};\n'
        count_addr_obstaculo = count_addr_obstaculo + 1

    if (count_addr < 16383):
        relacao_str = relacao_str + f'[{count_addr}..{16383}]:0;\n'
    if (count_addr_obstaculo < 2043):
        obstaculo_str = obstaculo_str + f'[{count_addr_obstaculo}..{2043}]:0;\n'

    relacao_str = relacao_str + f'END;'
    text_file = open(nome_arquivo_relacao, "w")
    text_file.write(relacao_str)
    text_file.close()

    obstaculo_str = obstaculo_str + f'END;'
    text_file = open(nome_arquivo_obstaculo, "w")
    text_file.write(obstaculo_str)
    text_file.close()

    import shutil

    shutil.copyfile(nome_arquivo_relacao, f'../../../Projetos/NiosDijkstra/mem_relacoes.mif')
    shutil.copyfile(nome_arquivo_obstaculo, f'../../../Projetos/NiosDijkstra/mem_obstaculo.mif')

def dict_2_vector(dict_mem,
                obstaculos,
                max_bits_relacao=10,
                max_bits_custo=4,
                nome_arquivo_relacao="../mem_relacoes.txt",
                nome_arquivo_obstaculo="../mem_obstaculo.txt",
                max_relacoes=8):

    """Converte uma memória em python para o formato mif do quartus"""
    num_nos = len(dict_mem.mem)
    relacao_str = f''
    obstaculo_str = f''
    count_addr = 0
    count_addr_obstaculo = 0
    valor_maximo_bin = ''
    for idx2 in range(max_bits_relacao + max_bits_custo):
        valor_maximo_bin = valor_maximo_bin + "1"
    valor_maximo_int = int(valor_maximo_bin, 2)
    for endereco, linha in dict_mem.mem.items():
        """
            {} places a variable into a string
            0 takes the variable at argument position 0
            : adds formatting options for this variable (otherwise it would represent decimal 6)
            08 formats the number to eight digits zero-padded on the left
            b converts the number to its binary representation
        """
        linha_relacao = ""
        count_vizinho = 0
        # relacao_str = relacao_str + f'\tNo - {(count_addr)/8}\n'
        for relacao, obstaculo, custo in linha:
            relacao_bin = ('{0:0' + f"{max_bits_relacao}" + 'b}').format(round_to_bin(relacao, max_bits_relacao))
            custo_bin = ('{0:0' + f"{max_bits_custo}" + 'b}').format(round_to_bin(custo, max_bits_custo))
            relacao_custo_bin = relacao_bin + custo_bin
            # relacao_custo_bin = relacao_bin
            relacao_custo_int = int(relacao_custo_bin, 2)
            if len(relacao_bin) > max_bits_relacao or len(custo_bin) > max_bits_custo:
                break
            if count_addr == 0:
                relacao_str = relacao_str + f'{relacao_custo_int}'
            else:
                relacao_str = relacao_str + f'\n{relacao_custo_int}'
            count_addr=count_addr+1
            count_vizinho = count_vizinho + 1


        for idx in range(max_relacoes-count_vizinho):
            relacao_str = relacao_str + f'\n{valor_maximo_int}'
            count_addr = count_addr + 1

        if endereco in obstaculos:
            obstaculo_str = obstaculo_str + f'{1}'
        else:
            obstaculo_str = obstaculo_str + f'{0}'
        obstaculo_str = obstaculo_str + f'\n'
        count_addr_obstaculo = count_addr_obstaculo + 1

    # relacao_str = relacao_str + f'END;'
    text_file = open(nome_arquivo_relacao, "w")
    text_file.write(relacao_str)
    text_file.close()

    # obstaculo_str = obstaculo_str + f'END;'
    text_file = open(nome_arquivo_obstaculo, "w")
    text_file.write(obstaculo_str)
    text_file.close()

def dict_2_include(dict_mem,
                obstaculos,
                max_bits_relacao=10,
                max_bits_custo=4,
                nome_arquivo_relacao="../mem_relacoes.h",
                nome_arquivo_obstaculo="../mem_obstaculo.h",
                max_relacoes=8):

    """Converte uma memória em python para o formato C"""
    relacao_str = ''
    obstaculo_str = ''
    count_addr = 0
    count_addr_obstaculo = 0
    valor_maximo_bin = ''
    for idx2 in range(max_bits_relacao + max_bits_custo):
        valor_maximo_bin = valor_maximo_bin + "1"
    valor_maximo_int = int(valor_maximo_bin, 2)
    for endereco, linha in dict_mem.mem.items():
        """
            {} places a variable into a string
            0 takes the variable at argument position 0
            : adds formatting options for this variable (otherwise it would represent decimal 6)
            08 formats the number to eight digits zero-padded on the left
            b converts the number to its binary representation
        """
        count_vizinho = 0

        for relacao, obstaculo, custo in linha:
            relacao_bin = ('{0:0' + f"{max_bits_relacao}" + 'b}').format(round_to_bin(relacao, max_bits_relacao))
            custo_bin = ('{0:0' + f"{max_bits_custo}" + 'b}').format(round_to_bin(custo, max_bits_custo))
            relacao_custo_bin = relacao_bin + custo_bin
            # relacao_custo_bin = relacao_bin
            relacao_custo_int = int(relacao_custo_bin, 2)
            if len(relacao_bin) > max_bits_relacao or len(custo_bin) > max_bits_custo:
                break

            relacao_str = relacao_str + f'addRelation(nodes[{count_addr}], nodes[{relacao}], {custo});\n'

            count_vizinho = count_vizinho + 1
        count_addr = count_addr + 1


        # for idx in range(max_relacoes-count_vizinho):
        #     relacao_str = relacao_str + f'{count_addr}\t:{valor_maximo_int};\n'
        #     count_addr = count_addr + 1

        if endereco in obstaculos:
            obstaculo_str = obstaculo_str + f'{count_addr_obstaculo}\t:{1};\n'
        else:
            obstaculo_str = obstaculo_str + f'{count_addr_obstaculo}\t:{0};\n'
        count_addr_obstaculo = count_addr_obstaculo + 1

    text_file = open(nome_arquivo_relacao, "w")
    text_file.write(relacao_str)
    text_file.close()

    obstaculo_str = obstaculo_str + f'END;'
    text_file = open(nome_arquivo_obstaculo, "w")
    text_file.write(obstaculo_str)
    text_file.close()

def salvar_param_sim(**kwargs):
    text_file = open("../defines.vh", "w")
    if 'max_bits_relacao' in kwargs:
        max_bits_relacao = kwargs['max_bits_relacao']
        text_file.write(f"`define ADDR_WIDTH {kwargs['max_bits_relacao']}\n")
        # text_file.write(f"`define ADDR_WIDTH 11\n")

    if 'fonte' in kwargs:
        text_file.write(f"`define FONTE {32}'d{kwargs['fonte']}\n")

    if 'destino' in kwargs:
        text_file.write(f"`define DESTINO {32}'d{kwargs['destino']}\n")

    if 'custo' in kwargs:
        text_file.write(f"`define CUSTO_CAMINHO {32}'d{kwargs['custo']}\n")

    if 'custo_width' in kwargs:
        text_file.write(f"`define CUSTO_WIDTH {32}'d{kwargs['custo_width']}\n")

    if 'max_vizinhos' in kwargs:
        text_file.write(f"`define MAX_VIZINHOS {32}'d{kwargs['max_vizinhos']}\n")

    if 'distancia_width' in kwargs:
        text_file.write(f"`define DISTANCIA_WIDTH {32}'d{kwargs['distancia_width']}\n")

    if 'max_ativos' in kwargs:
        print(f"Max Ativos {kwargs['max_ativos']}")
        if kwargs['max_ativos'] < 8:
            text_file.write(f"`define MAX_ATIVOS 32'd64\n")
            print(f"Max Ativos define {8}")
        else:
            maximo_prox_8 = kwargs['max_ativos'] + (8 - kwargs['max_ativos']%8)
            text_file.write(f"`define MAX_ATIVOS {32}'d{maximo_prox_8}\n")
            print(f"Max Ativos define {maximo_prox_8}")

        # maximo_prox_8 = kwargs['max_ativos'] + (8 - kwargs['max_ativos'] % 8)
        # text_file.write(f"`define MAX_ATIVOS {32}'d{maximo_prox_8}\n")
        # print(f"Max Ativos define {maximo_prox_8}")



    if 'menor_caminho' in kwargs:
        texto = "`define MENOR_CAMINHO {"
        count = 0;
        for relacao in kwargs['menor_caminho']:
            count += 1
            if count < len(kwargs['menor_caminho']):
                texto = texto + f"{max_bits_relacao}'d{relacao}, "
            else:
                texto = texto + f"{max_bits_relacao}'d{relacao}"
        texto = texto + "}"

        text_file.write(f"`define TAMANHO_CAMINHO {count}\n")
        text_file.write(texto)

    text_file.close()


