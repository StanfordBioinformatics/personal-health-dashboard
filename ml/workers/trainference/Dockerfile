FROM python:3.7

COPY src/dependencies.txt /home/src/

RUN pip install -r /home/src/dependencies.txt

COPY install/ /home/install/

COPY src/ml-cluster-service-account.json /home/src/

# Install GCP.
#RUN tar -C /home/install/ -xvf /home/install/google-cloud-sdk-VERSION-linux-x86_64.tar
RUN tar -C /home/install/ -xvf /home/install/google-cloud-sdk-316.0.0-linux-x86_64.tar.gz
RUN /home/install/google-cloud-sdk/install.sh

RUN /home/install/google-cloud-sdk/bin/gcloud auth activate-service-account MLCluster-service-account@phd-project.iam.gserviceaccount.com --key-file=/home/src/MLCluster-service-account.json
RUN echo 'y' | /home/install/google-cloud-sdk/bin/bq init

# Install R.
RUN apt-get update
RUN apt-get -y --allow-unauthenticated install software-properties-common
RUN add-apt-repository "deb https://cloud.r-project.org/bin/linux/ubuntu $(lsb_release -cs)-cran35/"
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E298A3A825C0D65DFD57CBB651716619E084DAB9
RUN apt-get -y --allow-unauthenticated install r-base

# Install R dependencies.
RUN Rscript -e "install.packages(\"xts\", repos = \"http://cloud.r-project.org\")"

COPY src/ /home/src/
COPY w_dir/ /home/w_dir/

ENTRYPOINT ["python", "/home/src/main.py"]
