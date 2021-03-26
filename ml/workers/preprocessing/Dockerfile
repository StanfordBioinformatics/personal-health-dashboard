FROM python:3.7

COPY src/dependencies.txt /home/src/

RUN pip install -r /home/src/dependencies.txt

COPY src/ /home/src/

ENTRYPOINT ["python", "/home/src/main.py"]
