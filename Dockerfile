FROM ubuntu:latest

RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    build-essential \
    autoconf \
    cmake \
    gawk \
    gperf \
    git \
    bison \
    flex \
    pkg-config \
    python3 \
	libreadline-dev \
    tcl-dev \
    libffi-dev \
    libboost-filesystem-dev \
    libboost-iostreams-dev \
	libboost-python-dev \
    libboost-system-dev \
    zlib1g-dev \
 && apt-get autoclean && apt-get clean && apt-get -y autoremove \
 && update-ca-certificates \
 && rm -rf /var/lib/apt/lists

COPY . /tmp/recheck

RUN cd /tmp/recheck && \
    cmake -DCMAKE_BUILD_TYPE=Release . && \
    make && \
    make install && \
    rm -rf /tmp/recheck
