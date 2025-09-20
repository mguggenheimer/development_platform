FROM debian:bookworm-slim

# Configure apt sources for main, contrib, non-free, and non-free-firmware
RUN rm -f /etc/apt/sources.list.d/debian.sources && \
    echo "deb http://deb.debian.org/debian bookworm main contrib non-free non-free-firmware" > /etc/apt/sources.list && \
    echo "deb http://deb.debian.org/debian-security bookworm-security main contrib non-free non-free-firmware" >> /etc/apt/sources.list && \
    echo "deb http://deb.debian.org/debian bookworm-updates main contrib non-free non-free-firmware" >> /etc/apt/sources.list

# Install base dependencies and tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    python3-minimal \
    python3-pip \
    python3-dbg \
    python3-pytest \
    python3-flake8 \
    pylint \
    python3-usb \
    python3-scapy \
    python3-serial \
    python3-requests \
    python3-paramiko \
    python3-cffi \
    python3-setuptools \
    python3-wheel \
    python3-numpy \
    python3-pandas \
    python3-matplotlib \
    python3-dev \
    git \
    vim \
    zsh \
    tmux \
    htop \
    wget \
    curl \
    unzip \
    ca-certificates \
    libpcap-dev \
    libnetfilter-queue-dev \
    libusb-1.0-0-dev \
    libserialport-dev \
    wireless-tools \
    iw \
    aircrack-ng \
    firmware-linux-nonfree \
    firmware-misc-nonfree \
    tcpdump \
    net-tools \
    nmap \
    netcat-openbsd \
    gdb \
    valgrind \
    strace \
    make \
    cmake \
    pkg-config \
    jq \
    minicom \
    usbutils \
    udev \
    rsyslog \
    capstone-tool \
    python3-venv \
    iproute2 \
    iputils-ping \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# Install cross-compilers and QEMU emulation
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc-arm-linux-gnueabihf \
    gcc-aarch64-linux-gnu \
    gcc-riscv64-linux-gnu \
    gcc-mips-linux-gnu \
    gcc-mipsel-linux-gnu \
    gcc-powerpc-linux-gnu \
    gcc-powerpc64le-linux-gnu \
    libc6-dev-armhf-cross \
    libc6-dev-arm64-cross \
    libc6-dev-riscv64-cross \
    libc6-dev-mips-cross \
    libc6-dev-mipsel-cross \
    libc6-dev-powerpc-cross \
    libc6-dev-ppc64el-cross \
    libc6-armhf-cross \
    libc6-arm64-cross \
    libc6-riscv64-cross \
    libc6-mips-cross \
    libc6-mipsel-cross \
    libc6-powerpc-cross \
    libc6-ppc64el-cross \
    libi2c-dev \
    libgpiod-dev \
    libcurl4-openssl-dev \
    libssl-dev \
    libncurses-dev \
    libjson-c-dev \
    qemu-user-static \
    qemu-system-arm \
    qemu-system-aarch64 \
    qemu-system-mips \
    qemu-system-mipsel \
    qemu-system-ppc \
    qemu-system-ppc64 \
    qemu-system-riscv64 \
    qemu-system-x86 \
    qemu-utils \
    binfmt-support \
    && rm -rf /var/lib/apt/lists/*

# Fix dynamic linker paths and library paths for QEMU user mode emulation
RUN ln -sf /usr/arm-linux-gnueabihf/lib/ld-linux-armhf.so.3 /lib/ld-linux-armhf.so.3 && \
    ln -sf /usr/aarch64-linux-gnu/lib/ld-linux-aarch64.so.1 /lib/ld-linux-aarch64.so.1 && \
    mkdir -p /lib64 && \
    ln -sf /usr/aarch64-linux-gnu/lib/ld-linux-aarch64.so.1 /lib64/ld-linux-aarch64.so.1 && \
    ln -sf /usr/riscv64-linux-gnu/lib/ld-linux-riscv64-lp64d.so.1 /lib/ld-linux-riscv64-lp64d.so.1

# Set up library paths for cross-architecture dynamic linking
RUN echo "/usr/arm-linux-gnueabihf/lib" >> /etc/ld.so.conf && \
    echo "/usr/aarch64-linux-gnu/lib" >> /etc/ld.so.conf && \
    echo "/usr/riscv64-linux-gnu/lib" >> /etc/ld.so.conf && \
    echo "/usr/mips-linux-gnu/lib" >> /etc/ld.so.conf && \
    echo "/usr/mipsel-linux-gnu/lib" >> /etc/ld.so.conf && \
    echo "/usr/powerpc-linux-gnu/lib" >> /etc/ld.so.conf && \
    echo "/usr/powerpc64le-linux-gnu/lib" >> /etc/ld.so.conf && \
    ldconfig

# Set up non-root user and groups
RUN groupadd -r i2c && \
    useradd -m -s /bin/zsh devuser && \
    usermod -aG dialout,plugdev,i2c,sudo devuser && \
    echo "devuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Install Go
RUN wget -q https://go.dev/dl/go1.23.0.linux-amd64.tar.gz && \
    tar -C /usr/local -xzf go1.23.0.linux-amd64.tar.gz && \
    rm go1.23.0.linux-amd64.tar.gz

# Create Go directories and set permissions
RUN mkdir -p /home/devuser/go/{bin,src,pkg} && \
    chown -R devuser:devuser /home/devuser/go

# Install Android NDK (using a more stable version)
RUN wget -q https://dl.google.com/android/repository/android-ndk-r21e-linux-x86_64.zip && \
    unzip -q android-ndk-r21e-linux-x86_64.zip && \
    mv android-ndk-r21e /opt/android-ndk && \
    rm android-ndk-r21e-linux-x86_64.zip && \
    chown -R root:root /opt/android-ndk

# Install golangci-lint and Go tools as root first, then copy to user space
RUN export PATH=$PATH:/usr/local/go/bin && \
    export GOPATH=/tmp/go && \
    mkdir -p /tmp/go/bin && \
    curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b /usr/local/bin v1.61.0 && \
    /usr/local/go/bin/go install github.com/go-delve/delve/cmd/dlv@latest && \
    /usr/local/go/bin/go install github.com/OJ/gobuster/v3@v3.6.0 && \
    /usr/local/go/bin/go install github.com/ffuf/ffuf/v2@v2.1.0 && \
    /usr/local/go/bin/go install github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest && \
    /usr/local/go/bin/go install github.com/projectdiscovery/httpx/cmd/httpx@latest && \
    cp /tmp/go/bin/* /usr/local/bin/ 2>/dev/null || true && \
    rm -rf /tmp/go

# Switch to user context
USER devuser

# Install oh-my-zsh
RUN sh -c "$(wget -O- https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" -- --unattended

# Create and set up Python virtual environment
RUN python3 -m venv /home/devuser/venv && \
    /home/devuser/venv/bin/pip install --no-cache-dir --upgrade pip setuptools wheel

# Install Python packages in virtual environment
RUN /home/devuser/venv/bin/pip install --no-cache-dir \
    black==24.8.0 \
    flake8==7.1.0 \
    adafruit-circuitpython-busdevice \
    pylibftdi \
    python-nmap \
    impacket \
    keystone-engine \
    requests \
    paramiko \
    scapy \
    cryptography \
    pycryptodome \
    numpy \
    pandas \
    matplotlib \
    && /home/devuser/venv/bin/pip install --no-cache-dir pwntools==4.12.0

# Copy custom .zshrc (this should be done last)
COPY --chown=devuser:devuser .zshrc /home/devuser/.zshrc

# Set working directory
WORKDIR /workspace

# Set environment variables
ENV PATH="/home/devuser/venv/bin:/usr/local/go/bin:/home/devuser/go/bin:/opt/android-ndk/toolchains/llvm/prebuilt/linux-x86_64/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
ENV GOPATH="/workspace/go"
ENV GOROOT="/usr/local/go"

# Default command
CMD ["/bin/zsh"]
