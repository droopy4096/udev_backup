#!/bin/bash

TEST_DEV=${1}
eval $(/sbin/blkid -o udev -p ${TEST_DEV})
if [ "$ID_FS_TYPE" == 'LVM2_member' ]
then
  VG_NAME=$(pvdisplay  -c ${TEST_DEV} | cut -d: -f2)
else
  VG_NAME=""
fi

echo "LVM_VG_NAME=${VG_NAME}"
