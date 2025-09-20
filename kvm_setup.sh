#!/bin/bash
# Kernel Development Setup Script with Analysis Tools for DFIR/Red Team

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "=== Kernel Development Environment Setup ==="

# Install QEMU and KVM
echo -e "${GREEN}[+] Installing QEMU/KVM...${NC}"
sudo apt update
sudo apt install -y \
    qemu-system-x86 \
    qemu-utils \
    libvirt-daemon-system \
    libvirt-clients \
    bridge-utils \
    virt-manager \
    cloud-image-utils

# Install kernel development tools on host
echo -e "${GREEN}[+] Installing kernel build tools...${NC}"
sudo apt install -y \
    build-essential \
    linux-headers-$(uname -r) \
    libncurses-dev \
    bison \
    flex \
    libssl-dev \
    libelf-dev \
    bc \
    rsync \
    cpio \
    gdb

# Create kernel development directory structure
echo -e "${GREEN}[+] Setting up directory structure...${NC}"
mkdir -p ~/kernel-dev/{modules,test-vms,kernels}

# Download Ubuntu cloud image for testing
echo -e "${GREEN}[+] Downloading Ubuntu 22.04 LTS cloud image...${NC}"
cd ~/kernel-dev/test-vms

if [ ! -f ubuntu-22.04-server-cloudimg-amd64.img ]; then
    wget https://cloud-images.ubuntu.com/releases/22.04/release/ubuntu-22.04-server-cloudimg-amd64.img
else
    echo "Ubuntu image already exists, skipping download"
fi

# Create a backing file for the VM
echo -e "${GREEN}[+] Creating VM disk...${NC}"
qemu-img create -f qcow2 -b ubuntu-22.04-server-cloudimg-amd64.img -F qcow2 test-vm.qcow2 10G

# Create cloud-init configuration with kernel analysis tools
echo -e "${GREEN}[+] Creating cloud-init configuration with kernel analysis tools...${NC}"
cat > user-data << 'EOF'
#cloud-config
password: ubuntu
chpasswd: { expire: False }
ssh_pwauth: True

packages:
  # Build essentials for kernel modules
  - build-essential
  - linux-headers-generic
  - make
  - gcc
  - git
  - vim
  
  # Kernel debugging and tracing
  - linux-tools-generic
  - linux-tools-common
  - trace-cmd
  - kernelshark
  - systemtap
  - systemtap-runtime
  - crash
  - makedumpfile
  - kmod
  
  # Module analysis
  - module-init-tools
  
  # Network driver testing
  - tcpdump
  - netcat-openbsd
  - ethtool
  - iproute2
  - net-tools
  
  # System monitoring
  - sysstat
  - htop
  - iotop
  - procinfo
  
  # Rootkit detection
  - unhide
  
  # Debugging
  - gdb
  - python3-pip
  - python3-dev

runcmd:
  # Install GEF for kernel debugging
  - wget -q -O /home/ubuntu/.gdbinit-gef.py https://raw.githubusercontent.com/hugsy/gef/main/gef.py
  - echo "source /home/ubuntu/.gdbinit-gef.py" >> /home/ubuntu/.gdbinit
  - chown ubuntu:ubuntu /home/ubuntu/.gdbinit*
  
  # Enable kernel debugging features
  - |
    cat >> /etc/sysctl.conf << 'SYSCTL'
    # Enable kernel debugging
    kernel.dmesg_restrict = 0
    kernel.kptr_restrict = 0
    kernel.yama.ptrace_scope = 0
    kernel.panic_on_oops = 0
    kernel.softlockup_panic = 0
    SYSCTL
    sysctl -p
  
  # Mount debugging filesystems
  - mount -t debugfs none /sys/kernel/debug 2>/dev/null || true
  - mount -t tracefs none /sys/kernel/tracing 2>/dev/null || true
  
  # Create kernel analysis helper functions
  - |
    cat >> /home/ubuntu/.bashrc << 'BASHRC'
    
    # Color output
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    NC='\033[0m'
    
    # Module management
    load_module() {
        echo -e "${GREEN}[+] Loading module $1${NC}"
        sudo insmod "$1" && sudo dmesg | tail -10
    }
    
    unload_module() {
        echo -e "${YELLOW}[-] Unloading module $1${NC}"
        sudo rmmod "$1" && echo "Module unloaded"
    }
    
    # Module analysis
    analyze_module() {
        echo -e "${GREEN}=== Module Analysis: $1 ===${NC}"
        echo "-- modinfo --"
        modinfo "$1" 2>/dev/null || modinfo "$1.ko" 2>/dev/null || echo "Not found"
        echo "-- Dependencies --"
        lsmod | grep -E "^$1|$1"
        echo "-- Parameters --"
        ls -la /sys/module/"$1"/parameters/ 2>/dev/null || echo "No parameters exposed"
        echo "-- Sections --"
        ls -la /sys/module/"$1"/sections/ 2>/dev/null || echo "No sections exposed"
        echo "-- Kernel taint --"
        cat /proc/sys/kernel/tainted
        echo "(0 = untainted, see kernel/panic.c for flag meanings)"
    }
    
    # Ftrace module functions
    trace_module() {
        echo -e "${GREEN}[+] Setting up ftrace for module $1${NC}"
        sudo sh -c "echo 0 > /sys/kernel/tracing/tracing_on"
        sudo sh -c "echo > /sys/kernel/tracing/trace"
        sudo sh -c "echo ':mod:$1' > /sys/kernel/tracing/set_ftrace_filter"
        sudo sh -c "echo function_graph > /sys/kernel/tracing/current_tracer"
        sudo sh -c "echo 1 > /sys/kernel/tracing/tracing_on"
        echo "Tracing enabled. Load your module now."
        echo "View with: sudo cat /sys/kernel/tracing/trace"
        echo "Stop with: sudo sh -c 'echo 0 > /sys/kernel/tracing/tracing_on'"
    }
    
    # Check for hidden modules
    check_hidden() {
        echo -e "${YELLOW}[!] Checking for hidden modules${NC}"
        echo "-- lsmod vs /proc/modules --"
        diff -u <(lsmod | tail -n +2 | awk '{print $1}' | sort) \
                <(cat /proc/modules | awk '{print $1}' | sort) || echo "No differences"
        echo "-- /sys/module vs /proc/modules --"
        diff -u <(ls /sys/module | sort) \
                <(cat /proc/modules | awk '{print $1}' | sort) || echo "No differences"
    }
    
    # Monitor kernel logs
    monitor_kernel() {
        echo -e "${GREEN}[+] Monitoring kernel logs${NC}"
        sudo dmesg -w
    }
    
    # Quick module template
    create_module() {
        if [ -z "$1" ]; then
            echo "Usage: create_module <name>"
            return
        fi
        mkdir -p "$1"
        cat > "$1/$1.c" << 'MODULE'
    #include <linux/init.h>
    #include <linux/module.h>
    #include <linux/kernel.h>
    
    static int __init mod_init(void)
    {
        pr_info("Module loaded\n");
        return 0;
    }
    
    static void __exit mod_exit(void)
    {
        pr_info("Module unloaded\n");
    }
    
    module_init(mod_init);
    module_exit(mod_exit);
    
    MODULE_LICENSE("GPL");
    MODULE_DESCRIPTION("Test Module");
    MODULE
        cat > "$1/Makefile" << 'MAKEFILE'
    obj-m += NAME.o
    
    all:
    	make -C /lib/modules/$(shell uname -r)/build M=$(PWD) modules
    
    clean:
    	make -C /lib/modules/$(shell uname -r)/build M=$(PWD) clean
    MAKEFILE
        sed -i "s/NAME/$1/g" "$1/Makefile"
        echo "Module template created in $1/"
    }
    
    # Aliases for quick access
    alias km='sudo dmesg | tail -20'
    alias kmc='sudo dmesg -C'
    alias trace='cd /sys/kernel/tracing'
    alias modules='lsmod | less'
    
    export PS1='\[\033[01;32m\]kernel-vm\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]$ '
    
    echo -e "${GREEN}Kernel analysis environment ready!${NC}"
    echo "Commands: load_module, unload_module, analyze_module, trace_module, check_hidden"
    BASHRC
    chown ubuntu:ubuntu /home/ubuntu/.bashrc

final_message: |
  Kernel Test VM Ready!
  
  Tools installed:
  - Kernel build environment
  - Ftrace & SystemTap
  - GDB with GEF
  - Module analysis utilities
  
  Quick start:
  - create_module <name>: Generate module template
  - load_module <file>: Load kernel module
  - analyze_module <name>: Inspect loaded module
  - trace_module <name>: Trace module functions
  - check_hidden: Look for rootkit modules
EOF

cat > meta-data << 'EOF'
instance-id: test-vm
local-hostname: kernel-test
EOF

# Create cloud-init ISO
cloud-localds cloud-init.iso user-data meta-data

# Create helper scripts
echo -e "${GREEN}[+] Creating helper scripts...${NC}"

# Script to launch Ubuntu test VM
cat > ~/kernel-dev/start-test-vm.sh << 'EOF'
#!/bin/bash
cd ~/kernel-dev/test-vms

echo "Starting Kernel Analysis VM..."
echo "Login: ubuntu / Password: ubuntu"
echo "SSH: ssh -p 2222 ubuntu@localhost"
echo "Exit: Ctrl-A, then X"
echo ""
echo "First boot: 2-3 minutes to install tools"
echo ""

qemu-system-x86_64 \
    -m 2G \
    -smp 2 \
    -hda test-vm.qcow2 \
    -cdrom cloud-init.iso \
    -nographic \
    -serial mon:stdio \
    -net nic \
    -net user,hostfwd=tcp::2222-:22 \
    -enable-kvm 2>/dev/null || \
qemu-system-x86_64 \
    -m 2G \
    -smp 2 \
    -hda test-vm.qcow2 \
    -cdrom cloud-init.iso \
    -nographic \
    -serial mon:stdio \
    -net nic \
    -net user,hostfwd=tcp::2222-:22
EOF

# Other scripts remain the same...
cat > ~/kernel-dev/ssh-vm.sh << 'EOF'
#!/bin/bash
ssh -p 2222 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ubuntu@localhost
EOF

cat > ~/kernel-dev/copy-to-vm.sh << 'EOF'
#!/bin/bash
if [ $# -eq 0 ]; then
    echo "Usage: $0 <file-to-copy> [destination]"
    exit 1
fi
DEST=${2:-"~/"}
scp -P 2222 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$1" ubuntu@localhost:"$DEST"
EOF

cat > ~/kernel-dev/reset-vm.sh << 'EOF'
#!/bin/bash
cd ~/kernel-dev/test-vms
rm -f test-vm.qcow2
qemu-img create -f qcow2 -b ubuntu-22.04-server-cloudimg-amd64.img -F qcow2 test-vm.qcow2 10G
echo "VM reset complete"
EOF

chmod +x ~/kernel-dev/*.sh

# Clean up
cd ~/kernel-dev/test-vms
rm -f user-data meta-data

# Done
echo -e "\n${GREEN}=== Setup Complete ===${NC}"
echo ""
echo "Kernel analysis VM configured with:"
echo "  • Ftrace & kernel tracing"
echo "  • Module development tools"
echo "  • Rootkit detection utilities"
echo "  • GDB with GEF"
echo ""
echo "Start VM: ~/kernel-dev/start-test-vm.sh"
echo "SSH to VM: ~/kernel-dev/ssh-vm.sh"
echo ""
echo -e "${RED}Test kernel modules in a KVM only, never on your host${NC}"
