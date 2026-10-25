# MeuLinux

Distro Linux própria, baseada em Debian 13 (trixie), com desktop XFCE, em português do Brasil. Gera uma ISO bootável (BIOS e UEFI) usando o Debian live-build.

Atenção: este projeto foi escrito sem acesso à internet para testar o build. Se algum passo falhar, veja `out/build.log` e me mande o erro.

## Como gerar a ISO

### Opção 1: GitHub Actions (sem precisar de PC Linux)

1. Suba esta pasta para um repositório no GitHub.
2. Abra a aba Actions, escolha "Construir ISO" e toque em Run workflow.
3. Quando terminar (20 a 40 min), baixe o artefato `iso`.

### Opção 2: no seu Linux (Debian ou Ubuntu)

```
sudo ./build.sh
```

Precisa de uns 10 GB livres e internet. A ISO sai em `out/meulinux-0.1-amd64.iso`.

### Opção 3: qualquer Linux com Docker

```
docker run --rm --privileged -v "$PWD":/work -w /work debian:trixie bash ./build.sh
```

## Testar

```
./test-qemu.sh
```

Ou grave em um pendrive (confira o dispositivo com `lsblk`, o `dd` apaga tudo no destino):

```
sudo dd if=out/meulinux-0.1-amd64.iso of=/dev/sdX bs=4M status=progress conv=fsync
```

No modo live, o usuário é `live` e a senha é `live`.

## Testar a ISO no próprio GitHub (sem PC)

O workflow "Testar ISO no runner" baixa a ISO do último build e a inicia em uma VM (QEMU) dentro do runner.

- Modo `screenshot`: tira 3 fotos da tela durante o boot. Baixe o artefato `telas` para ver se chegou ao desktop.
- Modo `remoto`: abre a tela por VNC pela rede Tailscale. Crie o secret `TS_AUTHKEY` (Settings > Secrets and variables > Actions), rode o workflow e conecte um cliente VNC no endereço mostrado no resumo da execução. Precisa do app do Tailscale no seu aparelho.

Rode "Construir ISO" antes, para existir o artefato `iso`.

## Personalizar

| O que mudar | Onde |
|---|---|
| Nome, versão, idioma, teclado, fuso | `config.env` |
| Programas incluídos | `packages.list` |
| Arquivos extras (wallpapers, configs) | pasta `overlay/` (espelha a raiz do sistema) |
| Identidade do sistema (os-release, issue) | trecho do hook em `build.sh` |

Depois de editar, rode o build de novo.

## Próximos passos

- Instalador gráfico: adicionar `calamares` e `calamares-settings-debian` ao `packages.list` (precisa de ajustes de configuração depois).
- Logo, wallpaper e tema: colocar em `overlay/usr/share/` e configurar o XFCE em `overlay/etc/skel/.config/xfce4/`.
- Repositório próprio de pacotes `.deb` e kernel customizado.
