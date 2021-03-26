FROM python:3.7

LABEL maintainer = "amiraa@stanford.edu"

COPY src/dependencies.txt /home/src/

RUN pip install -r /home/src/dependencies.txt

COPY src/ /home/src/

RUN pip install -r /home/src/dependencies.txt

ENTRYPOINT ["python", "/home/src/main.py"]
