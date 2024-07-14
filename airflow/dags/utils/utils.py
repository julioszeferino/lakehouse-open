import os
from typing import List, Dict
from datetime import datetime

def lista_arquivos(diretorio_pai: str) -> List[str]:
    lista_arquivos: List[str] = []
    for raiz, diretorios, arquivos in os.walk(diretorio_pai):
        for arquivo in arquivos:
            lista_arquivos.append(os.path.join(raiz, arquivo))
    return lista_arquivos

def define_path_hdfs(diretorio_hdfs: str, lista_arquivos_upload: List[str]) -> Dict[str,str]:

    data_hoje = datetime.now().strftime("%Y%m%d_%H%M%S")

    return {
        path_arquivo: f'{diretorio_hdfs}{path_arquivo.replace("/opt/airflow/data", "")}_{data_hoje}'
        for path_arquivo in lista_arquivos_upload
    }


