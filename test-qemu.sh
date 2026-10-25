#!/usr/bin/env bash
# Abre a ISO gerada em uma máquina virtual QEMU para teste rápido.
set -euo pipefail
cd "$(dirname "$0")"

ISO="$(ls -1 out/*.iso 2>/dev/null | head -n1 || true)"
if [[ -z "$ISO" ]]; then
  echo "Nenhuma ISO em out/. Rode ./build.sh antes." >&2
  exit 1
fi

if ! command -v qemu-system-x86_64 >/dev/null 2>&1; then
  echo "Instale o QEMU: sudo apt install qemu-system-x86" >&2
  exit 1
fi

KVM=()
if [[ -w /dev/kvm ]]; then
  KVM=(-enable-kvm -cpu host)
fi

exec qemu-system-x86_64 "${KVM[@]}" -m 3072 -smp 2 -cdrom "$ISO" -boot d -vga virtio
