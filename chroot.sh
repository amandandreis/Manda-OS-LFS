#!/bin/bash

##################################################
# Script para montar el entorno chroot en LFS.
# Amanda Andreis
##################################################

# Verifica si se está ejecutando como root
if [ $EUID -ne 0 ]; then
    echo "Este script debe ser ejecutado como root."
    exit 1
fi

# Configuración de variables
LFS=/mnt/manda-lfs

# Montaje de sistemas de archivos virtuales
echo "Montando sistemas de archivos virtuales..."
mount -v --bind /dev $LFS/dev
mount -vt devpts devpts -o gid=5,mode=0620 $LFS/dev/pts
mount -vt proc proc $LFS/proc
mount -vt sysfs sysfs $LFS/sys
mount -vt tmpfs tmpfs $LFS/run

# Verifica y monta /dev/shm si es necesario
if [ -h $LFS/dev/shm ]; then
    install -v -d -m 1777 $LFS$(realpath /dev/shm)
else
    mount -vt tmpfs -o nosuid,nodev tmpfs $LFS/dev/shm
fi

# Montaje de las variables EFI
echo "Montando efivarfs..."
mount -vt efivarfs efivarfs $LFS/sys/firmware/efi/efivars

# Montar la partición EFI
mount UUID=25A3-DA3B /boot/efi

# Configuración del PATH para el entorno chroot
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# Entrar en el entorno chroot
echo "Entrando en el entorno chroot..."
chroot "$LFS" /usr/bin/env -i   \
    HOME=/root                  \
    TERM="$TERM"                \
    PS1='(lfs chroot) \u:\w\$ ' \
    PATH=/usr/bin:/usr/sbin     \
    MAKEFLAGS="-j$(nproc)"      \
    TESTSUITEFLAGS="-j$(nproc)" \
    /bin/bash --login

echo "Saliste del entorno chroot."
