#!/bin/bash

SPARK_WORKLOAD=$1

echo "SPARK_WORKLOAD: $SPARK_WORKLOAD"

/etc/init.d/ssh start

if [ "$SPARK_WORKLOAD" == "master" ];
then

  if [ -e "/opt/spark/success/HDFSFORMAT.txt" ]; then
    echo "HDFS formatado."
  else
    echo "Formatando o HDFS..."
    hdfs namenode -format
    echo "HDFS formatado."
  fi
  

  # Inicializa os processos no master
  hdfs --daemon start namenode
  hdfs --daemon start secondarynamenode # geralmente colocamos em uma segunda maquina
  yarn --daemon start resourcemanager # nao iniciamos o spark no master, iniciamos no worker, aqui vamos usar o yarn para gerenciar os recursos

  while ! hdfs dfs -mkdir -p /spark-logs;
  do
    echo "Falha ao criar a pasta /spark-logs no hdfs"
  done
  echo "Criada a pasta /spark-logs no hdfs"
  hdfs dfs -mkdir -p /opt/spark/data
  echo "Criada a pasta /opt/spark/data no hdfs"

  hdfs dfs -mkdir -p /landing_zone
  hdfs dfs -mkdir -p /tmp
  hdfs dfs -mkdir -p /user
  hdfs dfs -mkdir -p /user/hive
  hdfs dfs -mkdir -p /user/hive/warehouse
  hdfs dfs -chmod g+w /user/hive/warehouse
  hdfs dfs -chmod g+w /tmp
  echo "Criadas as pastas do Hive Metastore no hdfs"

  if [ -e "/opt/spark/success/HDFSFORMAT.txt" ]; then
    echo "database do hive iniciado."
  else
    echo "Inicializando o database do hive..."
    schematool -dbType postgres -initSchema
    echo "database do hive iniciado."
    mkdir -p /opt/spark/success
    touch /opt/spark/success/HDFSFORMAT.txt
  fi

  echo "iniciando o hive server"
  mkdir -p /opt/hive/servidor/logs
  hive --service hiveserver2  >> /opt/hive/servidor/hiveserver2.log 2>&1 &
  pidhive=$!

  # Cria diretorios do lakehouse
  hdfs dfs -mkdir -p /user/hive/warehouse/bronze
  hdfs dfs -mkdir -p /user/hive/warehouse/silver
  hdfs dfs -mkdir -p /user/hive/warehouse/gold

  # copiando os jars
  cp /opt/spark/jars_personalizados/*.jar /opt/spark/jars/

  hdfs dfsadmin -safemode leave
  hdfs dfsadmin -report

  zeppelin-daemon.sh start


elif [ "$SPARK_WORKLOAD" == "worker" ];
then

  # Inicializa processos no worker
  hdfs --daemon start datanode
  yarn --daemon start nodemanager

  # copiando os jars
  cp /opt/spark/jars_personalizados/*.jar /opt/spark/jars/
  
elif [ "$SPARK_WORKLOAD" == "history" ];
then
  # Inicializa o history server
  sleep 10
  start-history-server.sh
fi

tail -f /dev/null
