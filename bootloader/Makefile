CC      := gcc
LD      := ld
OBJCOPY := objcopy

ROOT_DIR  := $(abspath ..)
BUILD_DIR := $(ROOT_DIR)/build/NebLoader

EFI_FILE := $(ROOT_DIR)/build/NebLoader.efi
ELF_FILE := $(BUILD_DIR)/NebLoader.so

EFI_INCLUDE := /usr/include/efi
EFI_LIB_DIR := /usr/lib

EFI_CRT := $(EFI_LIB_DIR)/crt0-efi-x86_64.o
EFI_LDS := $(EFI_LIB_DIR)/elf_x86_64_efi.lds

CFLAGS := \
	-I$(EFI_INCLUDE) \
	-I$(EFI_INCLUDE)/x86_64 \
	-DEFI_FUNCTION_WRAPPER \
	-std=c11 \
	-ffreestanding \
	-fpic \
	-fno-stack-protector \
	-fno-stack-check \
	-fshort-wchar \
	-mno-red-zone \
	-maccumulate-outgoing-args \
	-m64 \
	-O2 \
	-Wall \
	-Wextra

LDFLAGS := \
	-nostdlib \
	-znocombreloc \
	-T $(EFI_LDS) \
	-shared \
	-Bsymbolic \
	-L$(EFI_LIB_DIR)

OBJCOPY_FLAGS := \
	-j .text \
	-j .sdata \
	-j .data \
	-j .dynamic \
	-j .rodata \
	-j .rel \
	-j .rela \
	-j .rel.* \
	-j .rela.* \
	-j .rel* \
	-j .rela* \
	-j .areloc \
	-j .reloc

.PHONY: all clean

all: $(EFI_FILE)

$(EFI_FILE): $(ELF_FILE)
	$(OBJCOPY) $(OBJCOPY_FLAGS) \
		-O efi-app-x86_64 \
		$< $@

$(ELF_FILE): $(BUILD_DIR)/main.o
	$(LD) $(LDFLAGS) \
		$(EFI_CRT) \
		$< \
		-lefi \
		-lgnuefi \
		-o $@

$(BUILD_DIR)/main.o: main.c
	mkdir -p $(BUILD_DIR)
	$(CC) $(CFLAGS) -c $< -o $@

