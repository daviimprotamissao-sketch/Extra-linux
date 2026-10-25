#!/usr/bin/env bash
# Constrói a ISO bootável da distro usando Debian live-build.
# Uso: sudo ./build.sh   (precisa de Debian/Ubuntu ou de um container Debian)
set -euo pipefail

cd "$(dirname "$0")"
ROOT="$PWD"
# shellcheck source=config.env
source ./config.env

BUILD_DIR="$ROOT/build"
OUT_DIR="$ROOT/out"

if [[ $EUID -ne 0 ]]; then
  echo "Execute como root: sudo ./build.sh" >&2
  exit 1
fi

if ! command -v apt-get >/dev/null 2>&1; then
  echo "Este script precisa de Debian/Ubuntu. Em outras distros, use Docker (veja o README)." >&2
  exit 1
fi

echo ">> Instalando dependências de build"
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y \
  live-build debootstrap xorriso squashfs-tools mtools dosfstools cpio \
  syslinux syslinux-common syslinux-utils isolinux \
  grub-pc-bin grub-efi-amd64-bin ca-certificates debian-archive-keyring

if [[ -d "$BUILD_DIR" ]]; then
  echo ">> Limpando build anterior"
  (cd "$BUILD_DIR" && lb clean --purge) || true
  rm -rf "$BUILD_DIR"
fi
mkdir -p "$BUILD_DIR" "$OUT_DIR"
cd "$BUILD_DIR"

echo ">> Configurando live-build (${DEBIAN_SUITE}, ${ARCH})"
lb config \
  --distribution "$DEBIAN_SUITE" \
  --architectures "$ARCH" \
  --binary-images iso-hybrid \
  --bootloaders "syslinux,grub-efi" \
  --debian-installer none \
  --archive-areas "main contrib non-free non-free-firmware" \
  --iso-application "$DISTRO_NAME" \
  --iso-publisher "$DISTRO_NAME" \
  --iso-volume "${DISTRO_NAME} ${DISTRO_VERSION}" \
  --bootappend-live "boot=live components quiet splash hostname=${DISTRO_ID} username=${LIVE_USER} locales=${LOCALE} keyboard-layouts=${KEYBOARD} timezone=${TIMEZONE}" \
  --memtest none

echo ">> Copiando lista de pacotes e arquivos extras"
mkdir -p config/package-lists config/hooks/live config/includes.chroot
cp "$ROOT/packages.list" config/package-lists/custom.list.chroot
if [[ -d "$ROOT/overlay" ]]; then
  cp -a "$ROOT/overlay/." config/includes.chroot/
fi

echo ">> Gerando hook de identidade visual (nome da distro)"
cat > config/hooks/live/0100-branding.hook.chroot <<EOF
#!/bin/sh
set -e
cat > /etc/os-release <<OSR
PRETTY_NAME="${DISTRO_NAME} ${DISTRO_VERSION}"
NAME="${DISTRO_NAME}"
VERSION_ID="${DISTRO_VERSION}"
VERSION="${DISTRO_VERSION}"
ID=${DISTRO_ID}
ID_LIKE=debian
OSR
echo "${DISTRO_NAME} ${DISTRO_VERSION}" > /etc/issue
echo "${DISTRO_NAME} ${DISTRO_VERSION}" > /etc/issue.net
EOF
chmod +x config/hooks/live/0100-branding.hook.chroot

echo ">> Construindo a ISO (pode levar de 15 a 40 minutos)"
lb build 2>&1 | tee "$OUT_DIR/build.log"

ISO_SRC="$(find "$BUILD_DIR" -maxdepth 1 -name '*.iso' | head -n1)"
if [[ -z "$ISO_SRC" ]]; then
  echo "Falha: nenhuma ISO foi gerada. Veja out/build.log" >&2
  exit 1
fi

ISO_NAME="${DISTRO_ID}-${DISTRO_VERSION}-${ARCH}.iso"
mv "$ISO_SRC" "$OUT_DIR/$ISO_NAME"
(cd "$OUT_DIR" && sha256sum "$ISO_NAME" > "$ISO_NAME.sha256")

if [[ -n "${SUDO_USER:-}" ]]; then
  chown -R "$SUDO_USER" "$OUT_DIR"
fi

echo
echo "Pronto! ISO em: out/$ISO_NAME"
