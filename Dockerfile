FROM ubuntu

LABEL maintainer='nidhoggfgg <nidhoggfgg@gmail.com>'

ENV HUGO_VERSION=0.107.0 \
    SITE_ROOT=/blog \
    BIND_IP="0.0.0.0"

# install the package
RUN apt-get update \
    && apt-get install wget git -y

# install hugo
RUN  wget https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_extended_${HUGO_VERSION}_linux-amd64.deb \
        -O /tmp/hugo.deb \
    && cd /tmp \
    && dpkg -i hugo.deb

COPY docker_hugo.sh hugo.sh

# make the site dir and remove tmp file
RUN mkdir -p ${SITE_ROOT} \
    && rm -rf /tmp/*

RUN git config --global --add safe.directory /blog

WORKDIR ${SITE_ROOT}

VOLUME ${SITE_ROOT}

EXPOSE 1313

ENTRYPOINT [ "/hugo.sh" ]
CMD [ "--bind ${BIND_IP}", "--buildDrafts" ]
