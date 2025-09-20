# Cross-compilation Makefile for dev-sandbox container
# Designed to work within VSCode dev container environment

PROJECT_NAME ?= $(shell basename $(PWD))
SRC_DIR = src
INCLUDE_DIR = include
BUILD_DIR = build
BIN_DIR = bin

# Source files
SOURCES = $(wildcard $(SRC_DIR)/*.c)
HEADERS = $(wildcard $(INCLUDE_DIR)/*.h $(SRC_DIR)/*.h)
OBJECTS_BASE = $(patsubst $(SRC_DIR)/%.c,$(BUILD_DIR)/%.o,$(SOURCES))

# Cross-compilers (available in container)
CC_ARM = arm-linux-gnueabihf-gcc
CC_AARCH64 = aarch64-linux-gnu-gcc
CC_RISCV64 = riscv64-linux-gnu-gcc
CC_MIPS = mips-linux-gnu-gcc
CC_MIPSEL = mipsel-linux-gnu-gcc

# Common compiler flags
CFLAGS = -Wall -Wextra -O2 -I$(INCLUDE_DIR)
LDFLAGS = -static

# Architecture-specific object directories
ARM_BUILD_DIR = $(BUILD_DIR)/arm
AARCH64_BUILD_DIR = $(BUILD_DIR)/aarch64
RISCV64_BUILD_DIR = $(BUILD_DIR)/riscv64
MIPS_BUILD_DIR = $(BUILD_DIR)/mips
MIPSEL_BUILD_DIR = $(BUILD_DIR)/mipsel

# Architecture-specific objects
ARM_OBJECTS = $(patsubst $(SRC_DIR)/%.c,$(ARM_BUILD_DIR)/%.o,$(SOURCES))
AARCH64_OBJECTS = $(patsubst $(SRC_DIR)/%.c,$(AARCH64_BUILD_DIR)/%.o,$(SOURCES))
RISCV64_OBJECTS = $(patsubst $(SRC_DIR)/%.c,$(RISCV64_BUILD_DIR)/%.o,$(SOURCES))
MIPS_OBJECTS = $(patsubst $(SRC_DIR)/%.c,$(MIPS_BUILD_DIR)/%.o,$(SOURCES))
MIPSEL_OBJECTS = $(patsubst $(SRC_DIR)/%.c,$(MIPSEL_BUILD_DIR)/%.o,$(SOURCES))

# Final binaries
TARGETS = $(BIN_DIR)/$(PROJECT_NAME)_arm \
	$(BIN_DIR)/$(PROJECT_NAME)_aarch64 \
	$(BIN_DIR)/$(PROJECT_NAME)_riscv64 \
	$(BIN_DIR)/$(PROJECT_NAME)_mips \
	$(BIN_DIR)/$(PROJECT_NAME)_mipsel

.PHONY: all clean test analyze dirs help

# Default target
all: dirs $(TARGETS)

# Create necessary directories
dirs:
	@mkdir -p $(ARM_BUILD_DIR) $(AARCH64_BUILD_DIR) $(RISCV64_BUILD_DIR) $(MIPS_BUILD_DIR) $(MIPSEL_BUILD_DIR) $(BIN_DIR)

# ARM 32-bit
$(BIN_DIR)/$(PROJECT_NAME)_arm: $(ARM_OBJECTS)
	$(CC_ARM) $(ARM_OBJECTS) -o $@ $(LDFLAGS)

$(ARM_BUILD_DIR)/%.o: $(SRC_DIR)/%.c $(HEADERS)
	$(CC_ARM) $(CFLAGS) -c $< -o $@

# ARM 64-bit (AArch64)
$(BIN_DIR)/$(PROJECT_NAME)_aarch64: $(AARCH64_OBJECTS)
	$(CC_AARCH64) $(AARCH64_OBJECTS) -o $@ $(LDFLAGS)

$(AARCH64_BUILD_DIR)/%.o: $(SRC_DIR)/%.c $(HEADERS)
	$(CC_AARCH64) $(CFLAGS) -c $< -o $@

# RISC-V 64-bit
$(BIN_DIR)/$(PROJECT_NAME)_riscv64: $(RISCV64_OBJECTS)
	$(CC_RISCV64) $(RISCV64_OBJECTS) -o $@ $(LDFLAGS)

$(RISCV64_BUILD_DIR)/%.o: $(SRC_DIR)/%.c $(HEADERS)
	$(CC_RISCV64) $(CFLAGS) -c $< -o $@

# MIPS big-endian
$(BIN_DIR)/$(PROJECT_NAME)_mips: $(MIPS_OBJECTS)
	$(CC_MIPS) $(MIPS_OBJECTS) -o $@ $(LDFLAGS)

$(MIPS_BUILD_DIR)/%.o: $(SRC_DIR)/%.c $(HEADERS)
	$(CC_MIPS) $(CFLAGS) -c $< -o $@

# MIPS little-endian
$(BIN_DIR)/$(PROJECT_NAME)_mipsel: $(MIPSEL_OBJECTS)
	$(CC_MIPSEL) $(MIPSEL_OBJECTS) -o $@ $(LDFLAGS)

$(MIPSEL_BUILD_DIR)/%.o: $(SRC_DIR)/%.c $(HEADERS)
	$(CC_MIPSEL) $(CFLAGS) -c $< -o $@

# Individual architecture targets
arm: dirs $(BIN_DIR)/$(PROJECT_NAME)_arm
aarch64: dirs $(BIN_DIR)/$(PROJECT_NAME)_aarch64  
riscv64: dirs $(BIN_DIR)/$(PROJECT_NAME)_riscv64
mips: dirs $(BIN_DIR)/$(PROJECT_NAME)_mips
mipsel: dirs $(BIN_DIR)/$(PROJECT_NAME)_mipsel

# Test with QEMU emulation (container environment)
test: $(TARGETS)
	@echo "Testing cross-compiled binaries with QEMU..."
	@echo "ARM 32-bit:"
	@qemu-arm-static $(BIN_DIR)/$(PROJECT_NAME)_arm && echo "  ✓ PASS" || echo "  ✗ FAIL"
	@echo "ARM 64-bit (AArch64):"
	@qemu-aarch64-static $(BIN_DIR)/$(PROJECT_NAME)_aarch64 && echo "  ✓ PASS" || echo "  ✗ FAIL"
	@echo "RISC-V 64-bit:"
	@qemu-riscv64-static $(BIN_DIR)/$(PROJECT_NAME)_riscv64 && echo "  ✓ PASS" || echo "  ✗ FAIL"
	@echo "MIPS big-endian:"
	@qemu-mips-static $(BIN_DIR)/$(PROJECT_NAME)_mips && echo "  ✓ PASS" || echo "  ✗ FAIL"
	@echo "MIPS little-endian:"
	@qemu-mipsel-static $(BIN_DIR)/$(PROJECT_NAME)_mipsel && echo "  ✓ PASS" || echo "  ✗ FAIL"

# Security analysis with pwntools (container environment)

# Clean build artifacts
clean:
	rm -rf $(BUILD_DIR) $(BIN_DIR)

# Deep clean (including backup files)
distclean: clean
	find . -name "*~" -delete
	find . -name "*.orig" -delete
	find . -name "*.rej" -delete

# Show binary sizes
sizes: $(TARGETS)
	@echo "Binary sizes:"
	@ls -lh $(BIN_DIR)/$(PROJECT_NAME)_* | awk '{print $9 ": " $5}'

# Show compiler versions
compilers:
	@echo "Available cross-compilers:"
	@echo -n "ARM 32-bit: "; $(CC_ARM) --version | head -1
	@echo -n "ARM 64-bit: "; $(CC_AARCH64) --version | head -1
	@echo -n "RISC-V 64-bit: "; $(CC_RISCV64) --version | head -1
	@echo -n "MIPS BE: "; $(CC_MIPS) --version | head -1
	@echo -n "MIPS LE: "; $(CC_MIPSEL) --version | head -1

# Help target
help:
	@echo "Available targets:"
	@echo "  all       - Build for all architectures (default)"
	@echo "  arm       - Build ARM 32-bit binary only"
	@echo "  aarch64   - Build ARM 64-bit binary only"
	@echo "  riscv64   - Build RISC-V 64-bit binary only"
	@echo "  mips      - Build MIPS big-endian binary only"
	@echo "  mipsel    - Build MIPS little-endian binary only"
	@echo "  test      - Test all binaries with QEMU emulation"
	@echo "  analyze   - Security analysis of binaries"
	@echo "  sizes     - Show compiled binary sizes"
	@echo "  compilers - Show available cross-compiler versions"
	@echo "  clean     - Remove build artifacts"
	@echo "  distclean - Remove build artifacts and backup files"
	@echo "  help      - Show this help message"

analyze: $(TARGETS)
	@echo "Analyzing binary security properties..."
	@for file in $(BIN_DIR)/$(PROJECT_NAME)_*; do \
		echo "$$file:"; \
		file $$file; \
		echo ""; \
	done
