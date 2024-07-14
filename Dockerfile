FROM python:3.10-bullseye as hadoop-base

# Atualiza o SO e instala pacotes
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      sudo \
      curl \
      vim \
      nano \
      unzip \
      rsync \
      build-essential \
      software-properties-common \
      ssh && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Variáveis de ambiente
ENV SPARK_HOME=${SPARK_HOME:-"/opt/spark"}
ENV HADOOP_HOME=${HADOOP_HOME:-"/opt/hadoop"}
ENV YARN_HOME=${YARN_HOME:-"/opt/hadoop"}
ENV HIVE_HOME=${HIVE_HOME:-"/opt/hive"}
ENV JAVA_HOME=${JAVA_HOME:-"/opt/jdk"}
ENV ZEPPELIN_HOME=${ZEPPELIN_HOME:-"/opt/zeppelin"}

# Cria as pastas
RUN mkdir -p ${HADOOP_HOME} && mkdir -p ${SPARK_HOME} && mkdir -p ${HIVE_HOME} && mkdir -p ${JAVA_HOME} && mkdir -p ${ZEPPELIN_HOME}

WORKDIR ${SPARK_HOME}

# Download do arquivo de binários do JDK
RUN curl https://builds.openlogic.com/downloadJDK/openlogic-openjdk/8u412-b08/openlogic-openjdk-8u412-b08-linux-x64.tar.gz -o openlogic-openjdk-8u412-b08-linux-x64.tar.gz \
&& tar xvzf openlogic-openjdk-8u412-b08-linux-x64.tar.gz --directory /opt/jdk --strip-components 1 \
&& rm -rf openlogic-openjdk-8u412-b08-linux-x64.tar.gz

# Download do arquivo de binários do Spark
RUN curl https://archive.apache.org/dist/spark/spark-3.4.1/spark-3.4.1-bin-hadoop3.tgz -o spark-3.4.1-bin-hadoop3.tgz \
 && tar xvzf spark-3.4.1-bin-hadoop3.tgz --directory /opt/spark --strip-components 1 \
 && rm -rf spark-3.4.1-bin-hadoop3.tgz

# Download do arquivo de binários do Hadoop
RUN curl https://dlcdn.apache.org/hadoop/common/hadoop-3.3.6/hadoop-3.3.6.tar.gz -o hadoop-3.3.6.tar.gz \
&& tar xfz hadoop-3.3.6.tar.gz --directory /opt/hadoop --strip-components 1 \
&& rm -rf hadoop-3.3.6.tar.gz

# Download do arquivo de binários do Hive
RUN curl https://dlcdn.apache.org/hive/hive-3.1.3/apache-hive-3.1.3-bin.tar.gz -o apache-hive-3.1.3-bin.tar.gz \
&& tar xfz apache-hive-3.1.3-bin.tar.gz --directory /opt/hive --strip-components 1 \
&& rm -rf apache-hive-3.1.3-bin.tar.gz

# Download do arquivo de binários do Zeppelim
RUN curl https://dlcdn.apache.org/zeppelin/zeppelin-0.11.1/zeppelin-0.11.1-bin-all.tgz -o zeppelin-0.11.1-bin-all.tgz \
&& tar xfz zeppelin-0.11.1-bin-all.tgz --directory /opt/zeppelin --strip-components 1 \
&& rm -rf zeppelin-0.11.1-bin-all.tgz

# Prepara o ambiente com PySpark
FROM hadoop-base as pyspark

# Instala as dependências Python
RUN pip3 install --upgrade pip
COPY requirements.txt .
RUN pip3 install -r requirements.txt

ENV JAVA_HOME=${JAVA_HOME:-"/opt/jdk"}

# Adiciona os binários no PATH
ENV PATH="$SPARK_HOME/sbin:/opt/spark/bin:${PATH}"
ENV PATH="$HADOOP_HOME/bin:$HADOOP_HOME/sbin:${PATH}"
ENV PATH="$HIVE_HOME/bin:${PATH}"
ENV PATH="$ZEPPELIN_HOME/bin:${PATH}"
ENV CLASSPATH="$CLASSPATH:$HADOOP_HOME/lib/*:."
ENV CLASSPATH="$CLASSPATH:$HIVE_HOME/lib/*:."
ENV PATH="${PATH}:${JAVA_HOME}/bin"

# Variáveis de ambiente do spark
ENV SPARK_MASTER="spark://spark-master:7077"
ENV SPARK_MASTER_HOST spark-master
ENV SPARK_MASTER_PORT 7077
ENV PYSPARK_PYTHON python3
ENV HADOOP_CONF_DIR="$HADOOP_HOME/etc/hadoop"

# Usuário do HDFS e Yarn
ENV HDFS_NAMENODE_USER="root"
ENV HDFS_DATANODE_USER="root"
ENV HDFS_SECONDARYNAMENODE_USER="root"
ENV YARN_RESOURCEMANAGER_USER="root"
ENV YARN_NODEMANAGER_USER="root"

# Copiando os arquivos de configuracao do Hadoop
COPY config/hadoop/hadoop-env.sh $HADOOP_HOME/etc/hadoop/
COPY config/hadoop/*.xml "$HADOOP_HOME/etc/hadoop/"

# Copiando os arquivos de configuracao do Hive
COPY config/hive/hive-env.sh "$HIVE_HOME/conf/"
COPY config/hive/hive-site.xml "$HIVE_HOME/conf/"
COPY config/jars/postgresql-42.7.3.jar "$HIVE_HOME/lib/"

# Copiando os arquivos de configuracao do Spark
COPY config/spark/spark-defaults.conf "$SPARK_HOME/conf/"

# Copiando os arquivos de configuracao do Zeppelin
COPY config/zeppelin/* "$ZEPPELIN_HOME/conf/"

# Faz com que os binários sejam executáveis
RUN chmod u+x /opt/spark/sbin/* && \
    chmod u+x /opt/spark/bin/* && \
    chmod u+x /opt/hadoop/bin/* && \
    chmod u+x /opt/hadoop/sbin/* && \
    chmod u+x /opt/hive/bin/* && \
    chmod u+x /opt/zeppelin/bin/*

# Python PATH
ENV PYTHONPATH=$SPARK_HOME/python/:$PYTHONPATH

# SSH para autenticação sem senha no Hadoop
RUN ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa && \
  cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys && \
  chmod 600 ~/.ssh/authorized_keys

# Copia o arquivo de configuração do SSH
COPY config/ssh/ssh_config ~/.ssh/config

# Entrypoint script
COPY entrypoint.sh .
RUN mkdir -p ${SPARK_HOME}/jars_personalizados
ADD ./storage/jars/*.jar "$SPARK_HOME/jars_personalizados/"
COPY config/hadoop/*.xml "$HADOOP_HOME/etc/hadoop/"

# Ajusta o privilégio
RUN chmod +x entrypoint.sh

EXPOSE 50070 50075 50010 50020 50090 8020 9000 9864 9870 8030 8031 8032 8033 8040 8042 22 8088 10000 8080

# Executa o script quando inicializar um container
ENTRYPOINT ["./entrypoint.sh"]
