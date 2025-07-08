FROM ubuntu:22.04

# Avoid interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install sudo and create a test user
RUN apt-get update && apt-get install -y \
    sudo \
    curl \
    wget \
    git \
    && rm -rf /var/lib/apt/lists/*

# Create a test user with sudo privileges
RUN useradd -m -s /bin/bash testuser && \
    echo "testuser:testuser" | chpasswd && \
    usermod -aG sudo testuser && \
    echo "testuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Switch to test user
USER testuser
WORKDIR /home/testuser

# Copy dotfiles to container
COPY --chown=testuser:testuser . /home/testuser/dotfiles

# Set the working directory to dotfiles
WORKDIR /home/testuser/dotfiles

# Make bootstrap.sh executable
RUN chmod +x bootstrap.sh

# Default command
CMD ["/bin/bash"]