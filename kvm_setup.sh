#!/bin/bash
# Kernel Development Setup Script with Ubuntu VM for Testing

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

# Install kernel development tools
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

# Create cloud-init configuration
echo -e "${GREEN}[+] Creating cloud-init configuration...${NC}"
cat > user-data << 'EOF'
#cloud-config
password: ubuntu
chpasswd: { expire: False }
ssh_pwauth: True
packages:
  - build-essential
  - linux-headers-generic
  - make
  - gcc
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

echo "Starting Ubuntu 22.04 test VM..."
echo "Login: ubuntu / Password: ubuntu"
echo "SSH available on port 2222 after boot"
echo "To exit QEMU: Press Ctrl-A, then X"
echo ""
echo "First boot will take some time to initialize..."
echo ""

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

# Script to SSH into the VM
cat > ~/kernel-dev/ssh-vm.sh << 'EOF'
#!/bin/bash
echo "Connecting to test VM via SSH..."
echo "Password: ubuntu"
ssh -p 2222 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ubuntu@localhost
EOF

# Script to copy files to VM
cat > ~/kernel-dev/copy-to-vm.sh << 'EOF'
#!/bin/bash
if [ $# -eq 0 ]; then
    echo "Usage: $0 <file-to-copy> [destination]"
    echo "Example: $0 hello.ko"
    echo "Example: $0 hello.ko /tmp/"
    exit 1
fi

DEST=${2:-"~/"}
echo "Copying $1 to VM:$DEST"
echo "Password: ubuntu"
scp -P 2222 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$1" ubuntu@localhost:"$DEST"
EOF

# Script to reset VM to clean state
cat > ~/kernel-dev/reset-vm.sh << 'EOF'
#!/bin/bash
cd ~/kernel-dev/test-vms
echo "Resetting VM to clean state..."
rm -f test-vm.qcow2
qemu-img create -f qcow2 -b ubuntu-22.04-server-cloudimg-amd64.img -F qcow2 test-vm.qcow2 10G
echo "VM reset complete. Start with: ~/kernel-dev/start-test-vm.sh"
EOF

chmod +x ~/kernel-dev/*.sh

# Create sample kernel module
echo -e "${GREEN}[+] Creating sample kernel module...${NC}"
mkdir -p ~/kernel-dev/modules/hello
cat > ~/kernel-dev/modules/hello/hello.c << 'EOF'
#include <linux/init.h>
#include <linux/module.h>
#include <linux/kernel.h>

static int __init hello_init(void)
{
    printk(KERN_INFO "HELLO: Module loaded\n");
    printk(KERN_INFO "HELLO: Running on kernel %s\n", UTS_RELEASE);
    return 0;
}

static void __exit hello_exit(void)
{
    printk(KERN_INFO "HELLO: Module unloaded\n");
}

module_init(hello_init);
module_exit(hello_exit);

MODULE_LICENSE("GPL");
MODULE_DESCRIPTION("Test Kernel Module");
MODULE_AUTHOR("Developer");
MODULE_VERSION("1.0");
EOF

cat > ~/kernel-dev/modules/hello/Makefile << 'EOF'
obj-m += hello.o

KDIR ?= /lib/modules/$(shell uname -r)/build
PWD := $(shell pwd)

all:
	$(MAKE) -C $(KDIR) M=$(PWD) modules

clean:
	$(MAKE) -C $(KDIR) M=$(PWD) clean

install:
	$(MAKE) -C $(KDIR) M=$(PWD) modules_install

help:
	@echo "make       - Build module"
	@echo "make clean - Clean build files"
EOF

# Download Linux 6.1 LTS kernel source
echo -e "${GREEN}[+] Downloading Linux 6.1 LTS kernel source...${NC}"
cd ~/kernel-dev/kernels

if [ ! -d linux-6.1 ]; then
    if [ ! -f linux-6.1.tar.xz ]; then
        wget https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.1.tar.xz
    fi
    echo "Extracting kernel source (this may take some time)..."
    tar -xf linux-6.1.tar.xz
else
    echo "Kernel source already exists"
fi

# Clean up temporary files
cd ~/kernel-dev/test-vms
rm -f user-data meta-data

# Verification
echo -e "\n${GREEN}=== Installation Verification ===${NC}"

echo -n "QEMU: "
if command -v qemu-system-x86_64 &> /dev/null; then
    qemu-system-x86_64 --version | head -1
else
    echo -e "${RED}Not found${NC}"
fi

echo -n "Kernel headers: "
if [ -d /lib/modules/$(uname -r)/build ]; then
    echo -e "${GREEN}Installed${NC}"
else
    echo -e "${RED}Missing${NC}"
fi

echo -n "Ubuntu VM image: "
if [ -f ~/kernel-dev/test-vms/ubuntu-22.04-server-cloudimg-amd64.img ]; then
    echo -e "${GREEN}Ready${NC}"
else
    echo -e "${RED}Missing${NC}"
fi

echo -n "Kernel source: "
if [ -d ~/kernel-dev/kernels/linux-6.1 ]; then
    echo -e "${GREEN}Linux 6.1 LTS ready${NC}"
else
    echo -e "${RED}Missing${NC}"
fi

# Final instructions
echo -e "\n${GREEN}=== Setup Complete ===${NC}"
echo ""
echo "Directory structure:"
echo "  ~/kernel-dev/modules/   - Kernel modules"
echo "  ~/kernel-dev/test-vms/  - Ubuntu 22.04 test VM"
echo "  ~/kernel-dev/kernels/   - Linux 6.1 LTS source"
echo ""
echo -e "${YELLOW}Available workflow:${NC}"
echo "  1. Start VM:      ~/kernel-dev/start-test-vm.sh"
echo "  2. SSH to VM:     ~/kernel-dev/ssh-vm.sh"
echo "  3. Build modules directly in VM or copy from dev container"
echo "  4. Test safely in VM environment"
echo ""
echo -e "${YELLOW}Helper scripts:${NC}"
echo "  start-test-vm.sh - Start the Ubuntu VM"
echo "  ssh-vm.sh        - SSH into the VM"
echo "  copy-to-vm.sh    - Copy files to VM"
echo "  reset-vm.sh      - Reset VM to clean state"
echo ""
echo -e "${YELLOW}Note:${NC} Develop modules in the dev container, then build in the VM for correct kernel version matching"
echo ""
echo -e "${RED}WARNING: Always test kernel modules inside the vm, never on the host${NC}"
