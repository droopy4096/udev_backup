#!/bin/bash

# exec 3>&1 4>&2
# trap 'exec 2>&4 1>&3' 0 1 2 3


# exec 1>>/var/log/backup_udev_${1##*/}.log 2>&1

TEST_DEV=${1}
major=${2}
minor=${3}
PATH=${PATH}:/bin:/sbin:/usr/bin:/usr/sbin

eval $(/sbin/blkid -o udev -p ${TEST_DEV})
if [ "$ID_FS_TYPE" == 'LVM2_member' ]
then
  # ls -l ${TEST_DEV}
  /sbin/lvm pvscan -q --cache --activate ay --major $major --minor $minor > /dev/null
  VG_NAME=$(pvdisplay  -c ${TEST_DEV} | cut -d: -f2)
else
  VG_NAME=""
fi

echo "BACKUP_LVM_VG_NAME=${VG_NAME}"
