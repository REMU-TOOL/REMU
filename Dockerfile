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
    libboost-python-dev \
    libboost-system-dev \
    zlib1g-dev \
 && apt-get autoclean && apt-get clean && apt-get -y autoremove \
 && update-ca-certificates \
 && rm -rf /var/lib/apt/lists

# Install iverilog

RUN cd /tmp && \
    git clone https://gitlab.agileserve.org.cn:8001/remu/iverilog.git iverilog && \
    cd iverilog && \
    git checkout e9646bb && \
    sh autoconf.sh && \
    ./configure && \
    make -j`nproc` && \
    make install && \
    rm -rf /tmp/iverilog

# Build REMU

COPY . /tmp/remu

RUN cd /tmp/remu && \
    export ABCURL="https://gitlab.agileserve.org.cn:8001/remu/yosys-abc.git" && \
    cmake -DCMAKE_BUILD_TYPE=Release . && \
    make -j`nproc` && \
    make install && \
    rm -rf /tmp/remu
