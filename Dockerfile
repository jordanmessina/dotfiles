FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    curl \
    git \
    sudo \
    wget \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m -s /bin/bash testuser \
    && echo "testuser ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/testuser \
    && chmod 0440 /etc/sudoers.d/testuser

COPY --chown=testuser:testuser . /home/testuser/dotfiles

USER testuser
WORKDIR /home/testuser/dotfiles

CMD ["/bin/bash"]
