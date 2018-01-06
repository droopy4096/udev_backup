#!/bin/bash
#XXX add trap
# trap

BACKUP_VOLUME=${1}
MY_NAME=$(hostname)

BACKUP_BASE=/media/${BACKUP_VOLUME}_${MY_NAME}
BACKUP_LV=${BACKUP_VOLUME}/${MY_NAME}_backup
BACKUP_DEV=/dev/${BACKUP_LV}
TIMESTAMP=$(date "+%Y%m%d-%H%M")
vgchange -a y ${BACKUP_VOLUME}

if lvs --reportformat json  ${BACKUP_VOLUME}  | jq -r ".report[].lv[].lv_name" | grep -q "${MY_NAME}_backup"
then
  # we've got volume for our backups
  lvchange -a y ${BACKUP_LV}
  mkdir -p ${BACKUP_BASE}
  mount ${BACKUP_DEV} ${BACKUP_BASE}
  ls ${BACKUP_BASE}
  if [ -L ${BACKUP_BASE}/current ] 
  then
    rsync --files-from=/etc/backup/paths -arv --link-dest=${BACKUP_BASE}/current / ${BACKUP_BASE}/${TIMESTAMP}/
  else
    rsync --files-from=/etc/backup/paths -arv / ${BACKUP_BASE}/${TIMESTAMP}/
  fi
  [ -d ${BACKUP_BASE}/${TIMESTAMP} ] && ( cd ${BACKUP_BASE} && ln -sf ${TIMESTAMP} current )
  umount ${BACKUP_BASE}
fi

vgchange -a n ${BACKUP_VOLUME}
