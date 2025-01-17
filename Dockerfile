FROM debian:12
RUN apt-get update -y

# Buildroot mandatory package:
# https://buildroot.org/downloads/manual/manual.html#requirement-mandatory
RUN apt-get install -y \
        which \
        sed \ 
        make \
        binutils \
        diffutils \
        gcc \
        g++ \
        bash \
        patch \
        gzip \
        bzip2 \
        perl \
        tar \
        cpio \
        unzip \
        rsync \
        file \
        bc \
        findutils \
        wget
     

# Buildroot optional package:
# https://buildroot.org/downloads/manual/manual.html#requirement-optional
RUN apt-get install -y \
        python3 \
# User Interface dependecies \
        libncurses5 libncurses-dev \
#       qt5 \
#       glib2 gtk2 glade2 \
# Source fetching tools \
        git \
#       bazaar \
#       cvs \
#       subversion \
#       mercurial \
        rsync \
        openssh-client \
        javacc \
        asciidoc \
        w3m \
        dblatex \
# Editor \
        vim

# Dependecy for jailhouse
RUN apt-get install -y \
        python3-pip \
        python3-venv \
        python3-mako \
#       ssl/tls dependecies for pip \
        libssl-dev libncurses5-dev libsqlite3-dev libreadline-dev libtk8.6 libgdm-dev libdb4o-cil-dev libpcap-dev

WORKDIR /jailhouse-build
VOLUME /jailhouse-build/cache

# Get Buildroot, jaihouse hypervisor and linux kernel for jailhouse
RUN git clone --depth 1 -b 2023.11 https://gitlab.com/buildroot.org/buildroot.git && \
    git clone https://github.com/siemens/jailhouse.git && \ 
    git clone --depth 1 -b jailhouse-enabling/5.15 https://github.com/siemens/linux.git &&\
    tar -cvf linux.tar linux

# Prepare python venv for post jailhouse build
RUN python3 -m venv .jailhouse-venv && \
    . .jailhouse-venv/bin/activate && \
    pip3 install mako && \
    deactivate

ADD configs/ ./configs/
ADD scripts/ ./scripts
RUN mkdir logs materials

COPY ./docker-entrypoint.sh ./
ENTRYPOINT [ "/bin/bash", "./docker-entrypoint.sh" ]
CMD ["-s"]

