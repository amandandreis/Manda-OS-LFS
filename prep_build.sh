########################################################################
# Preparación para la Construcción - Amanda Andreis (Manda-OS)
########################################################################
# ----------------------------------------------------------------------
# Requisitos del Sistema Anfitrión
# ----------------------------------------------------------------------

cat > version-check.sh << "EOF"
#!/bin/bash
# Un script para listar las versiones de las herramientas de desarrollo críticas
# Modificado por Amanda Andreis para Manda-OS (LFS con systemd)

# Si tienes herramientas instaladas en otros directorios, ajusta el PATH aquí y en ~lfs/.bashrc 
LC_ALL=C
PATH=/usr/bin:/bin

# Función para manejar errores
bail() { echo "FATAL: $1"; exit 1; }
grep --version > /dev/null 2> /dev/null || bail "grep no funciona"
sed '' /dev/null || bail "sed no funciona"
sort /dev/null || bail "sort no funciona"

# Función para verificar las versiones de las herramientas
ver_check()
{
   if ! type -p $2 &>/dev/null
   then 
     echo "ERROR: No se puede encontrar $2 ($1)"; return 1; 
   fi
   v=$($2 --version 2>&1 | grep -E -o '[0-9]+\.[0-9\.]+[a-z]*' | head -n1)
   if printf '%s\n' $3 $v | sort --version-sort --check &>/dev/null
   then 
     printf "OK:    %-9s %-6s >= $3\n" "$1" "$v"; return 0;
   else 
     printf "ERROR: %-9s es DEMASIADO ANTIGUO (se requiere $3 o posterior)\n" "$1"; 
     return 1; 
   fi
}

# Función para verificar la versión del kernel
ver_kernel()
{
   kver=$(uname -r | grep -E -o '^[0-9\.]+')
   if printf '%s\n' $1 $kver | sort --version-sort --check &>/dev/null
   then 
     printf "OK:    Kernel de Linux $kver >= $1\n"; return 0;
   else 
     printf "ERROR: Kernel de Linux ($kver) es DEMASIADO ANTIGUO (se requiere $1 o posterior)\n" "$kver"; 
     return 1; 
   fi
}

# Coreutils primero porque --version-sort necesita Coreutils >= 8.30
ver_check Coreutils      sort     8.30 || bail "--version-sort no soportado"
ver_check Bash           bash     5.0
ver_check Binutils       ld       2.34
ver_check Bison          bison    3.0
ver_check Diffutils      diff     3.7
ver_check Findutils      find     4.6.0
ver_check Gawk           gawk     5.0
ver_check GCC            gcc      9.2
ver_check "GCC (C++)"    g++      9.2
ver_check Grep           grep     3.4
ver_check Gzip           gzip     1.10
ver_check M4             m4       1.4.18
ver_check Make           make     4.3
ver_check Patch          patch    2.7.6
ver_check Perl           perl     5.30
ver_check Python         python3  3.8
ver_check Sed            sed      4.8
ver_check Tar            tar      1.32
ver_check Texinfo        texi2any 6.7
ver_check Xz             xz       5.2.4
ver_kernel 5.8

# Verificar soporte para UNIX 98 PTY
if mount | grep -q 'devpts on /dev/pts' && [ -e /dev/ptmx ]
then echo "OK:    El Kernel de Linux soporta UNIX 98 PTY";
else echo "ERROR: El Kernel de Linux NO soporta UNIX 98 PTY"; fi

# Verificación de alias
alias_check() {
   if $1 --version 2>&1 | grep -qi $2
   then printf "OK:    %-4s es $2\n" "$1";
   else printf "ERROR: %-4s NO es $2\n" "$1"; fi
}
echo "Alias:"
alias_check awk GNU
alias_check yacc Bison
alias_check sh Bash

# Verificación del compilador
echo "Verificación del compilador:"
if printf "int main(){}" | g++ -x c++ -
then echo "OK:    g++ funciona";
else echo "ERROR: g++ NO funciona"; fi
rm -f a.out
EOF

# Ejecutar el script de verificación de versiones
bash version-check.sh

# ----------------------------------------------------------------------
# Creación de un Sistema de Archivos en la Partición
# ----------------------------------------------------------------------

# Reemplaza <xxx> y <yyy> por los nombres adecuados de los dispositivos
mkfs -v -t ext4 /dev/<xxx>
mkswap /dev/<yyy>

# ----------------------------------------------------------------------
# Establecer la Variable $LFS
# ----------------------------------------------------------------------

export LFS=/mnt/lfs

# Asegúrate de que $LFS esté correctamente configurado
echo $LFS

# ----------------------------------------------------------------------
# Montando la Nueva Partición
# ----------------------------------------------------------------------

# Montar la partición principal y crear los directorios necesarios
mkdir -pv $LFS
mount -v -t ext4 /dev/<xxx> $LFS
mkdir -v $LFS/home
mount -v -t ext4 /dev/<yyy> $LFS/home
/sbin/swapon -v /dev/<zzz>
