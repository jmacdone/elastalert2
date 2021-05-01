FROM python:slim-buster as builder

LABEL description="Elastalert 2 Official Image"
LABEL maintainer="Jason Ertel (jertel at codesim.com)"

COPY . /tmp/elastalert

RUN mkdir -p /opt/elastalert && \
    cd /tmp/elastalert && \
    pip install setuptools wheel && \
    python setup.py sdist bdist_wheel

FROM python:slim-buster

COPY --from=builder /tmp/elastalert/dist/*.tar.gz /tmp/

RUN apt-get update && apt-get -y upgrade &&\
    #apt-get install -y tzdata cargo libmagic1 jq curl &&\
    apt-get -y autoremove &&\
    rm -rf /var/lib/apt/lists/* &&\
    pip install /tmp/*.tar.gz &&\
    rm -rf /tmp/* &&\
    mkdir -p /opt/elastalert &&\
    echo "#!/bin/sh" >> /opt/elastalert/run.sh &&\
    echo "set -e" >> /opt/elastalert/run.sh &&\
    echo "elastalert-create-index --config /opt/elastalert/config.yaml" \
        >> /opt/elastalert/run.sh &&\
    echo "elastalert --config /opt/elastalert/config.yaml \"\$@\"" \
        >> /opt/elastalert/run.sh &&\
    chmod +x /opt/elastalert/run.sh &&\
    useradd -u 1000 -M -b /opt/elastalert -s /sbin/nologin \
        -c "ElastAlert User" elastalert

USER elastalert
ENV TZ "UTC"

WORKDIR /opt/elastalert
ENTRYPOINT ["/opt/elastalert/run.sh"]