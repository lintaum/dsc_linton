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


def salvar_param_sim(**kwargs):
    text_file = open("../defines.vh", "w")
    if 'max_bits_relacao' in kwargs:
        max_bits_relacao = kwargs['max_bits_relacao']
        text_file.write(f"`define ADDR_WIDTH {kwargs['max_bits_relacao']}\n")

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
        text_file.write(f"`define MAX_ATIVOS {32}'d{kwargs['max_ativos']}\n")

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


