FROM alpine
LABEL maintainer="Leonard Buskin <leonardbuskin@gmail.com>"

ARG VERSION=${VERSION:-master}
ENV SSDB_DATA_DIR=/ssdb/var

RUN apk add --no-cache --virtual .build-deps \
  curl gcc g++ make autoconf libc-dev libevent-dev linux-headers perl tar \
    && mkdir -p /ssdb/tmp \
    && curl -Lk "https://github.com/ideawu/ssdb/archive/${VERSION}.tar.gz" | \
       tar -xz -C /ssdb/tmp --strip-components=1 \
    && cd /ssdb/tmp \
    && make -j$(getconf _NPROCESSORS_ONLN) \
    && make install PREFIX=/ssdb \
	&& sed -e "s@home.*@home $(dirname $SSDB_DATA_DIR)@" \
	       -e "s/loglevel.*/loglevel info/" \
	       -e "s@work_dir = .*@work_dir = ${SSDB_DATA_DIR}@" \
		   -e "s@pidfile = .*@pidfile = /run/ssdb.pid@" \
		   -e "s@output:.*@output: stdout@" \
		   -e "s@level:.*@level: info@" \
		   -e "s@ip:.*@ip: 0.0.0.0@" \
		   -i /ssdb/ssdb.conf \
    && rm -rf /ssdb/tmp \
    && apk add --virtual .rundeps libstdc++ \
    && apk del .build-deps

EXPOSE 8888
VOLUME ${SSDB_DATA_DIR}

CMD ["/ssdb/ssdb-server", "/ssdb/ssdb.conf"]