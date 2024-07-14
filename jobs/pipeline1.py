from pyspark.sql import SparkSession
from pyspark.sql.types import DoubleType, FloatType, LongType, StructType,StructField, StringType
import os



def main():

    jar_path = "/opt/spark/jars"
    jars = ",".join([os.path.join(jar_path, jar)
                    for jar in os.listdir(jar_path) if jar.endswith(".jar")])

    # iniciando a sessao
    spark = SparkSession.builder \
        .appName("Cria Tabelas Bronze") \
        .config("spark.jars", jars) \
        .config("spark.sql.extensions", "org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions") \
        .config("spark.sql.catalog.spark_catalog", "org.apache.iceberg.spark.SparkSessionCatalog") \
        .config("spark.sql.catalog.spark_catalog.type", "hive") \
        .config("spark.sql.catalog.local", "org.apache.iceberg.spark.SparkCatalog") \
        .config("spark.sql.catalog.local.type", "hadoop") \
        .config("spark.sql.catalog.local.warehouse", "hdfs://spark-master:8080/user/hive/warehouse") \
        .config("spark.sql.defaultCatalog", "local") \
        .getOrCreate()

    # configs
    print(spark)
    print(SparkConf().getAll())
    spark.sparkContext.setLogLevel("INFO")  # Trocar para ERROR em producao

    schema = StructType([
    StructField("vendor_id", LongType(), True),
    StructField("trip_id", LongType(), True),
    StructField("trip_distance", FloatType(), True),
    StructField("fare_amount", DoubleType(), True),
    StructField("store_and_fwd_flag", StringType(), True)
    ])

    df = spark.createDataFrame([], schema)
    df.writeTo("bronze.nova_iorque").create()

    #  # Dados a serem inseridos
    # data = [
    #     (1, 123, 2.5, 10.0, 'N'),
    #     (2, 124, 3.0, 15.5, 'Y'),
    #     (3, 125, 4.0, 20.0, 'N')
    # ]

    # # Criando um DataFrame com os dados
    # df_data = spark.createDataFrame(data, schema)

    # # Inserindo os dados na tabela Iceberg
    # df_data.writeTo("bronze.nova_iorque").append()

if __name__ == '__main__':
    main()
