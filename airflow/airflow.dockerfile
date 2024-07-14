FROM apache/airflow:2.5.3-python3.10
ADD ./airflow/requirements.txt .
USER root
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
         gcc \
         heimdal-dev \
  && apt-get autoremove -yqq --purge \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*
USER airflow
RUN pip install -r requirements.txt
RUN pip uninstall -y argparse