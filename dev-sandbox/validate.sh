#!/bin/bash

# Container Validation Script - Fixed Version
# Tests all installed tools and cross-compilation toolchains

echo "====================================="
echo "Dev Sandbox Container Validation"
echo "====================================="
echo

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counter
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

test_command() {
    local name="$1"
    local command="$2"
    local expected_pattern="$3"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    echo -n "Testing $name... "
    
    if output=$(eval "$command" 2>&1); then
        if [ -z "$expected_pattern" ] || echo "$output" | grep -q "$expected_pattern"; then
            echo -e "${GREEN}PASS${NC}"
            PASSED_TESTS=$((PASSED_TESTS + 1))
            return 0
        else
            echo -e "${RED}FAIL${NC} (unexpected output)"
            echo "  Expected pattern: $expected_pattern"
            echo "  Got: $output"
            FAILED_TESTS=$((FAILED_TESTS + 1))
            return 1
        fi
    else
        echo -e "${RED}FAIL${NC} (command failed)"
        echo "  Error: $output"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        return 1
    fi
}

compile_test() {
    local arch="$1"
    local compiler="$2"
    local target_flag="$3"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    echo -n "Testing $arch cross-compilation ($compiler)... "
    
    # Create a simple test program
    cat > /tmp/test_${arch}.c << 'EOF'
#include <stdio.h>
int main() {
    printf("Hello from cross-compiled binary\n");
    return 0;
}
EOF
    
    # Attempt compilation
    if $compiler $target_flag -o /tmp/test_${arch} /tmp/test_${arch}.c 2>/dev/null; then
        if [ -f /tmp/test_${arch} ]; then
            echo -e "${GREEN}PASS${NC}"
            PASSED_TESTS=$((PASSED_TESTS + 1))
            rm -f /tmp/test_${arch} /tmp/test_${arch}.c
            return 0
        fi
    fi
    
    echo -e "${RED}FAIL${NC}"
    echo "  Failed to compile test program for $arch"
    FAILED_TESTS=$((FAILED_TESTS + 1))
    rm -f /tmp/test_${arch} /tmp/test_${arch}.c
    return 1
}

python_module_test() {
    local module="$1"
    local import_name="$2"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    echo -n "Testing Python module $module... "
    
    if python3 -c "import $import_name; print('OK')" 2>/dev/null | grep -q "OK"; then
        echo -e "${GREEN}PASS${NC}"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        return 0
    else
        echo -e "${RED}FAIL${NC}"
        echo "  Failed to import $import_name"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        return 1
    fi
}

echo "1. SYSTEM INFORMATION"
echo "====================="
test_command "OS Version" "cat /etc/os-release | grep PRETTY_NAME" "Debian"
test_command "Kernel" "uname -r" ""
test_command "Architecture" "uname -m" "x86_64"
echo

echo "2. BASIC DEVELOPMENT TOOLS"
echo "=========================="
test_command "GCC" "gcc --version" "gcc"
test_command "Make" "make --version" "GNU Make"
test_command "CMake" "cmake --version" "cmake"
test_command "Git" "git --version" "git"
test_command "Vim" "vim --version | head -1" "Vi IMproved"
test_command "Python3" "python3 --version" "Python 3"
test_command "Pip3" "pip3 --version" "pip"
echo

echo "3. CROSS-COMPILATION TOOLCHAINS"
echo "==============================="
compile_test "ARM" "arm-linux-gnueabihf-gcc" ""
compile_test "AArch64" "aarch64-linux-gnu-gcc" ""
compile_test "RISC-V" "riscv64-linux-gnu-gcc" ""
compile_test "MIPS" "mips-linux-gnu-gcc" ""
compile_test "MIPS-EL" "mipsel-linux-gnu-gcc" ""
compile_test "PowerPC" "powerpc-linux-gnu-gcc" ""
compile_test "PowerPC64LE" "powerpc64le-linux-gnu-gcc" ""

# Test cross-compiler versions
test_command "ARM GCC Version" "arm-linux-gnueabihf-gcc --version" "arm-linux-gnueabihf-gcc"
test_command "AArch64 GCC Version" "aarch64-linux-gnu-gcc --version" "aarch64-linux-gnu-gcc"
test_command "RISC-V GCC Version" "riscv64-linux-gnu-gcc --version" "riscv64-linux-gnu-gcc"
echo

echo "4. GO DEVELOPMENT ENVIRONMENT"
echo "============================="
test_command "Go Version" "go version" "go1.23"
test_command "Go Environment" "go env GOROOT" "/usr/local/go"
test_command "Go Path" "echo \$GOPATH" "/workspace/go"

# Test Go tools - Fixed patterns
test_command "Gobuster" "gobuster version 2>&1" "3.6"
test_command "FFUF" "ffuf -V" "ffuf"
test_command "Subfinder" "subfinder -version" "subfinder"
test_command "HTTPx" "httpx -version 2>&1" "v1.7"
test_command "Delve (dlv)" "dlv version" "Delve"
test_command "golangci-lint" "golangci-lint version" "golangci-lint"
echo

# Test Go compilation
echo -n "Testing Go compilation... "
TOTAL_TESTS=$((TOTAL_TESTS + 1))
cat > /tmp/test.go << 'EOF'
package main
import "fmt"
func main() {
    fmt.Println("Hello from Go!")
}
EOF

if go build -o /tmp/test_go /tmp/test.go 2>/dev/null && [ -f /tmp/test_go ]; then
    echo -e "${GREEN}PASS${NC}"
    PASSED_TESTS=$((PASSED_TESTS + 1))
    rm -f /tmp/test_go /tmp/test.go
else
    echo -e "${RED}FAIL${NC}"
    FAILED_TESTS=$((FAILED_TESTS + 1))
    rm -f /tmp/test_go /tmp/test.go
fi

echo "5. PYTHON VIRTUAL ENVIRONMENT"
echo "============================="
test_command "Virtual Environment" "which python3" "/home/devuser/venv/bin/python3"
test_command "Virtual Environment Pip" "which pip" "/home/devuser/venv/bin/pip"

# Test Python modules
python_module_test "Pwntools" "pwn"
python_module_test "Impacket" "impacket"
python_module_test "Keystone Engine" "keystone"
python_module_test "Requests" "requests"
python_module_test "Paramiko" "paramiko"
python_module_test "Scapy" "scapy"
python_module_test "Cryptography" "cryptography"
python_module_test "PyCryptodome" "Crypto"
python_module_test "NumPy" "numpy"
python_module_test "Pandas" "pandas"
python_module_test "Matplotlib" "matplotlib"
python_module_test "Black" "black"
python_module_test "Flake8" "flake8"
echo

echo "6. ANDROID NDK"
echo "=============="
test_command "Android NDK Path" "ls -d /opt/android-ndk" "/opt/android-ndk"
test_command "NDK Clang" "ls /opt/android-ndk/toolchains/llvm/prebuilt/linux-x86_64/bin/clang" "/opt/android-ndk/toolchains/llvm/prebuilt/linux-x86_64/bin/clang"
echo

echo "7. NETWORKING & SECURITY TOOLS"
echo "=============================="
test_command "Nmap" "nmap --version" "Nmap"
test_command "TCPdump" "tcpdump --version" "tcpdump"
test_command "Aircrack-ng" "aircrack-ng --help" "Aircrack-ng"
test_command "Netcat" "nc -h 2>&1" "usage"
test_command "Wget" "wget --version" "GNU Wget"
test_command "Curl" "curl --version" "curl"
echo

echo "8. DEBUGGING & ANALYSIS TOOLS"
echo "============================="
test_command "GDB" "gdb --version" "GNU gdb"
test_command "Valgrind" "valgrind --version" "valgrind"
test_command "Strace" "strace -V" "strace"
test_command "Capstone" "cstool -v 2>&1" "Capstone"
echo

echo "9. QEMU EMULATION SUPPORT"
echo "========================="
test_command "QEMU User Static" "qemu-arm-static --version" "qemu-arm"
test_command "QEMU System ARM" "qemu-system-arm --version" "QEMU emulator"
test_command "QEMU System AArch64" "qemu-system-aarch64 --version" "QEMU emulator"
test_command "QEMU System MIPS" "qemu-system-mips --version" "QEMU emulator"
test_command "QEMU System RISC-V" "qemu-system-riscv64 --version" "QEMU emulator"
test_command "QEMU System PowerPC" "qemu-system-ppc --version" "QEMU emulator"
test_command "QEMU System x86" "qemu-system-i386 --version" "QEMU emulator"
test_command "Binfmt Support" "which qemu-arm-static" "qemu-arm-static"

# Test QEMU user mode emulation
echo -n "Testing QEMU ARM emulation... "
TOTAL_TESTS=$((TOTAL_TESTS + 1))
cat > /tmp/qemu_test.c << 'EOF'
#include <stdio.h>
int main() {
    printf("QEMU ARM test successful\n");
    return 0;
}
EOF

if arm-linux-gnueabihf-gcc -static -o /tmp/qemu_test_arm /tmp/qemu_test.c 2>/dev/null; then
    if qemu-arm-static /tmp/qemu_test_arm 2>/dev/null | grep -q "successful"; then
        echo -e "${GREEN}PASS${NC}"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        echo -e "${RED}FAIL${NC} (execution failed)"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
else
    echo -e "${RED}FAIL${NC} (compilation failed)"
    FAILED_TESTS=$((FAILED_TESTS + 1))
fi
rm -f /tmp/qemu_test.c /tmp/qemu_test_arm
echo

echo "10. DEVELOPMENT LIBRARIES"
echo "======================="
test_command "libpcap-dev" "pkg-config --exists libpcap && echo OK" "OK"
test_command "libusb-dev" "pkg-config --exists libusb-1.0 && echo OK" "OK"
test_command "libssl-dev" "pkg-config --exists libssl && echo OK" "OK"
test_command "libcurl-dev" "pkg-config --exists libcurl && echo OK" "OK"
echo

echo "11. SHELL ENVIRONMENT"
echo "===================="
test_command "Zsh" "zsh --version" "zsh"
test_command "Oh-My-Zsh" "ls -d /home/devuser/.oh-my-zsh" "/home/devuser/.oh-my-zsh"
test_command "Tmux" "tmux -V" "tmux"
echo

echo "12. USER PERMISSIONS & GROUPS"
echo "============================="
test_command "User Groups" "groups devuser" "dialout.*plugdev.*i2c"
test_command "Sudo Access" "sudo -n true 2>/dev/null && echo OK || echo 'NOPASSWD not configured'" "OK"
echo

echo "====================================="
echo "VALIDATION SUMMARY"
echo "====================================="
echo "Total Tests: $TOTAL_TESTS"
echo -e "Passed: ${GREEN}$PASSED_TESTS${NC}"
echo -e "Failed: ${RED}$FAILED_TESTS${NC}"

if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "\n${GREEN}All tests passed! Container is ready for development.${NC}"
    exit 0
else
    echo -e "\n${YELLOW}Some tests failed. Please review the output above.${NC}"
    exit 1
fi
