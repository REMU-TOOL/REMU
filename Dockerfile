FROM ubuntu:latest

# Install required dependencies

RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    build-essential \
    autoconf \
    cmake \
    gawk \
    gperf \
    wget \
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

# Install iverilog 11.0

RUN cd /tmp && \
    wget -O iverilog.tar.gz https://github.com/steveicarus/iverilog/archive/refs/tags/v11_0.tar.gz && \
    mkdir -p iverilog && \
    tar xzf iverilog.tar.gz -C iverilog --strip-components 1 && \
    cd iverilog && \
    sh autoconf.sh && \
    ./configure && \
    make -j`nproc` && \
    make install && \
    rm -rf /tmp/iverilog.tar.gz /tmp/iverilog

# Build recheck

COPY . /tmp/recheck

RUN cd /tmp/recheck && \
    cmake -DCMAKE_BUILD_TYPE=Release . && \
    make -j`nproc` && \
    make install && \
    rm -rf /tmp/recheck
