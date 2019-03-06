#!/bin/bash

# This file contains utility functions used by rpi23-gen-image.sh

# SOURCE: https://github.com/drtyhlpr/rpi23-gen-image/blob/b9382705545375056057d989f959f275e562b17c/functions.sh

cleanup (){
  set +x
  set +e

  # Remove exports from nexmon
  unset KERNEL
  unset ARCH
  unset SUBARCH
  unset CCPLUGIN
  unset ZLIBFLATE
  unset Q
  unset NEXMON_SETUP_ENV
  unset HOSTUNAME
  unset PLATFORMUNAME

  # Identify and kill all processes still using files
  echo "killing processes using mount point ..."
  fuser -k "${R}"
  sleep 3
  fuser -9 -k -v "${R}"

  # Clean up temporary .password file
  if [ -r ".password" ] ; then
    shred -zu .password
  fi

  # Clean up all temporary mount points
  echo "removing temporary mount points ..."
  umount -l "${R}/proc" 2> /dev/null
  umount -l "${R}/sys" 2> /dev/null
  umount -l "${R}/dev/pts" 2> /dev/null
  umount "$BUILDDIR/mount/boot/firmware" 2> /dev/null
  umount "$BUILDDIR/mount" 2> /dev/null
  cryptsetup close "${CRYPTFS_MAPPING}" 2> /dev/null
  losetup -d "$ROOT_LOOP" 2> /dev/null
  losetup -d "$FRMW_LOOP" 2> /dev/null
  trap - 0 1 2 3 6
}

chroot_exec() {
  # Exec command in chroot
  LANG=C LC_ALL=C DEBIAN_FRONTEND=noninteractive chroot "${R}" "$@"
}

as_nobody() {
  # Exec command as user nobody
  sudo -E -u nobody LANG=C LC_ALL=C "$@"
}

install_readonly() {
  # Install file with user read-only permissions
  install -o root -g root -m 644 "$@"
}

install_exec() {
  # Install file with root exec permissions
  install -o root -g root -m 744 "$@"
}

use_template () {
  # Test if configuration template file exists
  if [ ! -r "./templates/${CONFIG_TEMPLATE}" ] ; then
    echo "error: configuration template ${CONFIG_TEMPLATE} not found"
    exit 1
  fi

  # Load template configuration parameters
  . "./templates/${CONFIG_TEMPLATE}"
}

chroot_install_cc() {
  # Install c/c++ build environment inside the chroot
  if [ -z "${COMPILER_PACKAGES}" ] ; then
    COMPILER_PACKAGES=$(chroot_exec apt-get -s install g++ make bc | grep "^Inst " | awk -v ORS=" " '{ print $2 }')
	# Install COMPILER_PACKAGES in chroot - NEVER do "${COMPILER_PACKAGES}" -> breaks uboot
    chroot_exec apt-get -q -y --allow-unauthenticated --no-install-recommends install ${COMPILER_PACKAGES}
  fi
}

chroot_remove_cc() {
  # Remove c/c++ build environment from the chroot
  if [ -n "${COMPILER_PACKAGES}" ] ; then
    chroot_exec apt-get -qq -y --auto-remove purge ${COMPILER_PACKAGES}
    COMPILER_PACKAGES=""
  fi
}

# https://serverfault.com/a/682849 - converts e.g. /24 to 255.255.255.0
cdr2mask ()
{
   # Number of args to shift, 255..255, first non-255 byte, zeroes
   set -- $(( 5 - ($1 / 8) )) 255 255 255 255 $(( (255 << (8 - ($1 % 8))) & 255 )) 0 0 0
   [ $1 -gt 1 ] && shift $1 || shift
   echo ${1-0}.${2-0}.${3-0}.${4-0}
}

# GPL v2.0 - #https://github.com/sakaki-/bcmrpi3-kernel-bis/blob/master/conform_config.sh
set_kernel_config() {
  # flag as $1, value to set as $2, config must exist at "./.config"
  TGT="CONFIG_${1#CONFIG_}"
  REP="${2}"
  if grep -q "^${TGT}[^_]" .config; then
    sed -i "s/^\(${TGT}=.*\|# ${TGT} is not set\)/${TGT}=${REP}/" .config
  else
    echo "${TGT}"="${2}" >> .config
  fi
}

# unset kernel config parameter
unset_kernel_config() {
  # unsets flag with the value of $1, config must exist at "./.config"
  TGT="CONFIG_${1#CONFIG_}"
  sed -i "s/^${TGT}=.*/# ${TGT} is not set/" .config
}
