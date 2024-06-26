ARG UBUNTU_RELEASE=22.04
FROM ubuntu:${UBUNTU_RELEASE}

LABEL maintainer "https://github.com/ehfd"

ARG UBUNTU_RELEASE

RUN apt-get clean && apt-get update && apt-get upgrade -y && apt-get install --no-install-recommends -y \
        apt-transport-https \
        apt-utils \
        ca-certificates \
        openssh-client \
        curl \
        iptables \
        git \
        gnupg \
        software-properties-common \
        supervisor \
        vim \
        sudo \
        git \
        make \
        gcc \
        python3.11 \
        jq \
        ag \
        wget && \
    rm -rf /var/lib/apt/list/*

RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
# Source Rust environment variables
RUN echo "source $HOME/.cargo/env" >> $HOME/.bashrc

# 下载并安装指定版本的Golang
RUN wget https://go.dev/dl/go1.22.2.linux-amd64.tar.gz \
    && tar -C /usr/local -xzf go1.22.2.linux-amd64.tar.gz \
    && rm go1.22.2.linux-amd64.tar.gz

# 设置环境变量
RUN echo "PATH=$PATH:/usr/local/go/bin" >> $HOME/.bashrc
ENV PATH=$PATH:/usr/local/go/bin


# NVIDIA Container Toolkit and Docker
RUN mkdir -pm755 /etc/apt/keyrings && curl -fsSL "https://download.docker.com/linux/ubuntu/gpg" | gpg --dearmor -o /etc/apt/keyrings/docker.gpg && chmod a+r /etc/apt/keyrings/docker.gpg && \
    mkdir -pm755 /etc/apt/sources.list.d && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(grep UBUNTU_CODENAME= /etc/os-release | cut -d= -f2 | tr -d '\"') stable" > /etc/apt/sources.list.d/docker.list && \
    mkdir -pm755 /usr/share/keyrings && curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg && \
    curl -fsSL "https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list" | sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | tee /etc/apt/sources.list.d/nvidia-container-toolkit.list > /dev/null && \
    apt-get update && apt-get install --no-install-recommends -y \
        docker-ce \
        docker-ce-cli \
        containerd.io \
        docker-buildx-plugin \
        docker-compose-plugin \
        nvidia-container-toolkit && \
    rm -rf /var/lib/apt/list/* && \
    nvidia-ctk runtime configure --runtime=docker

COPY modprobe start-docker.sh entrypoint.sh /usr/local/bin/
COPY supervisor/ /etc/supervisor/conf.d/
COPY logger.sh /opt/bash-utils/logger.sh

RUN chmod +x /usr/local/bin/start-docker.sh /usr/local/bin/entrypoint.sh /usr/local/bin/modprobe

VOLUME /var/lib/docker

ENTRYPOINT ["entrypoint.sh"]
CMD ["bash"]
