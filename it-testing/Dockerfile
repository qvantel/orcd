FROM python:alpine

RUN apk add --update \
    python \
    python-dev \
    py-pip \
    build-base \
    bash \
  && pip install nose \
  && rm -rf /var/cache/apk/*


COPY ./ /home/
WORKDIR /home
CMD ["nosetests"]

