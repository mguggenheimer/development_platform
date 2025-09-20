# Ensure oh-my-zsh is sourced first
export ZSH="/home/devuser/.oh-my-zsh"
ZSH_THEME="robbyrussell"
plugins=(git golang docker)
setopt aliases
source $ZSH/oh-my-zsh.sh

# Activate Python virtual environment
if [ -f /home/devuser/venv/bin/activate ]; then
    source /home/devuser/venv/bin/activate
fi

# Environment variables
export GOPATH="/workspace/go"
export GOROOT="/usr/local/go"
export PATH="/home/devuser/venv/bin:$GOROOT/bin:$GOPATH/bin:/opt/android-ndk/toolchains/llvm/prebuilt/linux-x86_64/bin:$PATH"

# Development aliases
alias ll='ls -la'
alias la='ls -A'
alias l='ls -CF'

# Cross-compiler aliases
alias gcc-arm='arm-linux-gnueabihf-gcc'
alias gcc-aarch64='aarch64-linux-gnu-gcc'
alias gcc-riscv='riscv64-linux-gnu-gcc'
alias gcc-mips='mips-linux-gnu-gcc'
alias gcc-mipsel='mipsel-linux-gnu-gcc'
alias gcc-powerpc='powerpc-linux-gnu-gcc'
alias gcc-ppc64el='powerpc64le-linux-gnu-gcc'

# Android NDK aliases (using clang from NDK r21e)
alias ndk-clang='$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin/clang'
alias ndk-clang++='$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin/clang++'

# Security tools
alias gobuster='gobuster'
alias ffuf='ffuf'
alias subfinder='subfinder'
alias httpx='httpx'

# Python security tools
alias impacket='python3 -c "import impacket; print(f\"Impacket {impacket.__version__} available\")"'
alias pwntools='python3 -c "import pwn; print(f\"Pwntools {pwn.__version__} available\")"'

# Quick development helpers
alias venv-activate='source /home/devuser/venv/bin/activate'
alias go-version='go version'
alias python-version='python3 --version'

# Welcome message
echo "Dev Sandbox Container Ready!"
echo "Cross-compilers: ARM, AArch64, RISC-V, MIPS, PowerPC"
echo "Python tools: $(python3 --version), pwntools, impacket"
echo "Go tools: $(go version | cut -d' ' -f3), gobuster, ffuf"
echo "Android NDK: Available at /opt/android-ndk"
