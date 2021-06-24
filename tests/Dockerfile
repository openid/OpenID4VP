FROM python:3-slim-buster
COPY requirements.txt /tmp/requirements.txt
RUN pip3 install -r /tmp/requirements.txt

WORKDIR /data
ENTRYPOINT [ "pytest", "-v", "--tb=short", "--color=yes" ]
