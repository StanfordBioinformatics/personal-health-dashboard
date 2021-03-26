FROM python:3

LABEL maintainer = "dcelis@ai.stanford.edu"

COPY src/ /home/src/

RUN pip install -r /home/src/dependencies.txt

ENTRYPOINT ["python", "/home/src/main.py"]
