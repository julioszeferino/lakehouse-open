from airflow.decorators import task
from airflow.decorators import dag
from datetime import datetime, timedelta
from airflow.providers.apache.hdfs.hooks.webhdfs import WebHDFSHook
from utils.utils import lista_arquivos, define_path_hdfs
from typing import Dict

_hookHDFS = WebHDFSHook(webhdfs_conn_id='conexao_hdfs')

@task.python
def upload_hdfs(hookHDFS, mapeamento_arquivos_upload):
    
    for fonte, destino in mapeamento_arquivos_upload.items():
        print(f"Upload: {fonte} -> {destino}")
   
        hookHDFS.load_file(
            source=fonte,
            destination=destino,
            overwrite=True,
        )
    print("Arquivos enviados!!")


@dag(
    description="Dag responsavel por importar os dados no hdfs",
    start_date=datetime(2021, 1, 1),
    schedule_interval=None,
    dagrun_timeout=timedelta(minutes=10),
    tags=["input", "etl"],
    catchup=False,
    max_active_runs=1,
)
def input_files_hdfs():

    mapeamento_arquivos_upload: Dict[str,str] = define_path_hdfs(
                    diretorio_hdfs="/landing_zone",
                    lista_arquivos_upload=lista_arquivos(diretorio_pai="/opt/airflow/data")
                )
   
    upload_hdfs(_hookHDFS, mapeamento_arquivos_upload)


input_files_hdfs_dag = input_files_hdfs()