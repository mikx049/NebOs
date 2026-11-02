#!/usr/bin/env bash

set -uo pipefail

# ==========================================
# NebOs Toolchain Checker
# ==========================================

# Colors
if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
    RED=$'\033[0;31m'
    GREEN=$'\033[0;32m'
    YELLOW=$'\033[1;33m'
    CYAN=$'\033[0;36m'
    BLUE=$'\033[0;34m'
    RESET=$'\033[0m'
else
    RED=''
    GREEN=''
    YELLOW=''
    CYAN=''
    BLUE=''
    RESET=''
fi

PASS=0
FAIL=0
WARN=0

# ==========================================
# Configuration
# ==========================================

EFI_INCLUDE_DIR="${GNU_EFI_INCLUDE_DIR:-/usr/include/efi}"

LIB_DIRS=(
    "${GNU_EFI_LIB_DIR:-/usr/lib}"
    /usr/lib64
    /usr/lib/x86_64-linux-gnu
    /usr/lib/gnuefi
)

# ==========================================
# Output functions
# ==========================================

header() {
    echo
    printf "${CYAN}"
    cat <<'EOF'
███╗   ██╗███████╗██████╗  ██████╗ ███████╗
████╗  ██║██╔════╝██╔══██╗██╔═══██╗██╔════╝
██╔██╗ ██║█████╗  ██████╔╝██║   ██║███████╗
██║╚██╗██║██╔══╝  ██╔══██╗██║   ██║╚════██║
██║ ╚████║███████╗██████╔╝╚██████╔╝███████║
╚═╝  ╚═══╝╚══════╝╚═════╝  ╚═════╝ ╚══════╝
EOF
    printf "${RESET}"
    echo
    printf "${BLUE}          NebOs Toolchain Checker${RESET}\n"
    printf "${BLUE}==========================================${RESET}\n"
    echo
}

section() {
    echo
    printf "${YELLOW}[%s]${RESET}\n" "$1"
}

info() {
    printf "${CYAN}%-25s${RESET} %s\n" "$1" "$2"
}

pause_check() {
    sleep 0.1
}

pass() {
    printf "${GREEN}[PASS]${RESET} %s\n" "$1"
    ((PASS+=1))
    pause_check
}

fail() {
    printf "${RED}[FAIL]${RESET} %s\n" "$1"
    ((FAIL+=1))
    pause_check
}

warn() {
    printf "${YELLOW}[WARN]${RESET} %s\n" "$1"
    ((WARN+=1))
    pause_check
}

# ==========================================
# Detection functions
# ==========================================

check_command() {
    local name="$1"
    local command="$2"

    if command -v "$command" >/dev/null 2>&1; then
        pass "$name: $(command -v "$command")"
    else
        fail "$name: command '$command' not found"
    fi
}

find_file() {
    local filename="$1"
    local directory

    for directory in "${LIB_DIRS[@]}"; do
        if [[ -f "$directory/$filename" ]]; then
            printf '%s\n' "$directory/$filename"
            return 0
        fi
    done

    return 1
}

check_file() {
    local description="$1"
    local path="$2"

    if [[ -f "$path" ]]; then
        pass "$description: $path"
    else
        fail "$description: missing ($path)"
    fi
}

# ==========================================
# System information
# ==========================================

header
sleep 1

section "System information"

DISTRO="Unknown"
DISTRO_ID="unknown"

if [[ -r /etc/os-release ]]; then
    source /etc/os-release
    DISTRO="${PRETTY_NAME:-${NAME:-Unknown}}"
    DISTRO_ID="${ID:-unknown}"
fi

HOST_ARCH="$(uname -m)"
KERNEL="$(uname -r)"

info "Distribution:" "$DISTRO"
info "Distribution ID:" "$DISTRO_ID"
info "Host architecture:" "$HOST_ARCH"
info "Kernel:" "$KERNEL"

# ==========================================
# Compiler information
# ==========================================

section "Compiler information"

if command -v gcc >/dev/null 2>&1; then
    GCC_TARGET="$(gcc -dumpmachine 2>/dev/null || echo Unknown)"
    GCC_VERSION="$(gcc -dumpfullversion -dumpversion 2>/dev/null || echo Unknown)"

    info "GCC version:" "$GCC_VERSION"
    info "Compiler target:" "$GCC_TARGET"

    if [[ "$GCC_TARGET" == x86_64* ]]; then
        pass "GCC target supports x86_64"
    else
        fail "GCC target is not x86_64: $GCC_TARGET"
    fi
else
    fail "GCC is not installed"
fi

if [[ "$HOST_ARCH" == "x86_64" ]]; then
    pass "Host architecture is x86_64"
else
    warn "Host is not x86_64; cross-compilation may be required"
fi

# ==========================================
# Required tools
# ==========================================

section "Required tools"

check_command "GCC" gcc
check_command "GNU Make" make
check_command "GNU Linker" ld
check_command "Objcopy" objcopy
check_command "NASM" nasm
check_command "Xorriso" xorriso
check_command "CPIO" cpio
check_command "Gzip" gzip

# ==========================================
# Optional development tools
# ==========================================

section "Optional development tools"

for tool in ccls readelf file bear; do
    if command -v "$tool" >/dev/null 2>&1; then
        pass "$tool: $(command -v "$tool")"
    else
        warn "$tool is not installed"
    fi
done

# ==========================================
# GNU-EFI headers
# ==========================================

section "GNU-EFI headers"

check_file "EFI main header" "$EFI_INCLUDE_DIR/efi.h"
check_file "EFI library header" "$EFI_INCLUDE_DIR/efilib.h"
check_file "EFI x86_64 bindings" "$EFI_INCLUDE_DIR/x86_64/efibind.h"

# ==========================================
# GNU-EFI libraries and linker files
# ==========================================

section "GNU-EFI libraries"

for filename in \
    crt0-efi-x86_64.o \
    elf_x86_64_efi.lds \
    libgnuefi.a \
    libefi.a
do
    if path="$(find_file "$filename")"; then
        pass "$filename: $path"
    else
        fail "$filename: not found"
    fi
done

# ==========================================
# Objcopy support
# ==========================================

section "EFI binary support"

if command -v objcopy >/dev/null 2>&1; then
    if objcopy --info 2>/dev/null | grep -q 'efi-app-x86_64'; then
        pass "Objcopy supports efi-app-x86_64"
    else
        warn "Objcopy EFI target not detected"
    fi
fi

# ==========================================
# Summary
# ==========================================

echo
printf "${BLUE}==========================================${RESET}\n"
printf "                  SUMMARY\n"
printf "${BLUE}==========================================${RESET}\n"

printf "${GREEN}Passed:${RESET}   %d\n" "$PASS"
printf "${RED}Failed:${RESET}   %d\n" "$FAIL"
printf "${YELLOW}Warnings:${RESET} %d\n" "$WARN"

echo

if (( FAIL > 0 )); then
    printf "${RED}NebOs toolchain check FAILED.${RESET}\n"
    exit 1
fi

printf "${GREEN}NebOs toolchain check PASSED.${RESET}\n"
exit 0
