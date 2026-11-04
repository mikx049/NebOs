.DEFAULT_GOAL := image

BUILD_DIR := build

ISO_DIR := $(BUILD_DIR)/iso
EFI_DIR := $(ISO_DIR)/boot
EFI_IMAGE := $(EFI_DIR)/efiboot.img

ISO_FILE := $(BUILD_DIR)/NebOs.iso

BOOTLOADER := $(BUILD_DIR)/NebLoader.efi
KERNEL := $(BUILD_DIR)/kernel/kernel.elf
ROOTFS := $(BUILD_DIR)/ROOTFS.cpio.gz

.PHONY: clean bootloader image

BEAR_EXISTS := $(shell command -v bear 2> /dev/null)

# ==========================================
# Clean
# ==========================================

clean:
	rm -rf $(BUILD_DIR)/*
	rm -f bootloader/compile_commands.json

# ==========================================
# Bootloader
# ==========================================

bootloader:
	mkdir -p $(BUILD_DIR)
ifdef BEAR_EXISTS
	cd bootloader && bear -- $(MAKE)
	sed -i 's|/usr/bin/gcc|/usr/bin/clang|g' bootloader/compile_commands.json
else
	$(MAKE) -C bootloader
endif

# ==========================================
# Image
# ==========================================

image: bootloader
	mkdir -p $(BUILD_DIR)

	@set -eu; \
	for tool in xorriso mkfs.fat mmd mcopy truncate; do \
		if ! command -v "$$tool" >/dev/null 2>&1; then \
			echo "Missing tool: $$tool"; \
			exit 1; \
		fi; \
	done; \
	\
	if [ ! -f "$(BOOTLOADER)" ]; then \
		echo "Bootloader not found: $(BOOTLOADER)"; \
		exit 1; \
	fi; \
	\
	echo "Preparing ISO directory..."; \
	rm -rf "$(ISO_DIR)"; \
	mkdir -p "$(EFI_DIR)"; \
	\
	echo "Creating EFI FAT32 image..."; \
	truncate -s 64M "$(EFI_IMAGE)"; \
	mkfs.fat -F 32 "$(EFI_IMAGE)"; \
	\
	echo "Creating EFI directories..."; \
	mmd -i "$(EFI_IMAGE)" ::/EFI; \
	mmd -i "$(EFI_IMAGE)" ::/EFI/BOOT; \
	\
	echo "Installing bootloader..."; \
	mcopy -i "$(EFI_IMAGE)" "$(BOOTLOADER)" ::/EFI/BOOT/BOOTX64.EFI; \
	\
	if [ -f "$(KERNEL)" ]; then \
		echo "Installing kernel..."; \
		mcopy -i "$(EFI_IMAGE)" "$(KERNEL)" ::/kernel.elf; \
	else \
		echo "Kernel not found, skipping."; \
	fi; \
	\
	if [ -f "$(ROOTFS)" ]; then \
		echo "Installing ROOTFS..."; \
		mcopy -i "$(EFI_IMAGE)" "$(ROOTFS)" ::/ROOTFS.cpio.gz; \
	else \
		echo "ROOTFS not found, skipping."; \
	fi; \
	\
	echo "Creating bootable UEFI ISO..."; \
	xorriso -as mkisofs \
		-R \
		-J \
		-V "NebOs" \
		-o "$(ISO_FILE)" \
		-eltorito-alt-boot \
		-e boot/efiboot.img \
		-no-emul-boot \
		-isohybrid-gpt-basdat \
		"$(ISO_DIR)"; \
	\
	echo "ISO created: $(ISO_FILE)"
