#!/bin/bash -x
#XXX add trap
# trap
exec 3>&1 4>&2
trap 'exec 2>&4 1>&3' 0 1 2 3
exec 1>>/var/log/backup.log 2>&1

PATH=${PATH}:/bin:/sbin:/usr/bin:/usr/sbin

BACKUP_VOLUME=${1}
MY_NAME=$(hostname)

BACKUP_BASE=/media/${BACKUP_VOLUME}_${MY_NAME}
BACKUP_LV=${BACKUP_VOLUME}/${MY_NAME}_backup
BACKUP_DEV=/dev/${BACKUP_LV}
TIMESTAMP=$(date "+%Y%m%d-%H%M")
vgchange -a y ${BACKUP_VOLUME}
SAVED_VOL=""
MAX_VOL=""

_notify_user(){
  user=$1
  user_id=$2
  bus=$3
  shift 3
  export DISPLAY=":0"
  export DBUS_SESSION_BUS_ADDRESS=$bus
  runuser -p -u $user -- /usr/bin/notify-send "$@"
}

notify_users(){
  for mybus in $(/bin/grep -hze '^DBUS_SESSION_BUS_ADDRESS=[a-zA-Z0-9:=,/-]*$' /proc/*/environ | \
                 tr '\000' "\n" | \
                 sort -u | \
                 grep -e '/bus$' | \
                 sed -e 's/DBUS_SESSION_BUS_ADDRESS=//g' | \
                 grep -v abstract)
  do 
    pre_user=${mybus##*/run/user/}
    user_id=${pre_user%%/*}
    user=$(id -nu $user_id)
    _notify_user $user $user_id $mybus "$@"
  done | sort -u
}

alsa_volume_save(){
  SAVED_VOL=$(amixer get Master | grep -F 'Mono:' | cut -d' ' -f 5)
  MAX_VOL=$(amixer get Master | grep -F 'Limits:' | cut -d' ' -f 7)
}

alsa_volume_set(){
  VOL=$1
  amixer cset iface=MIXER,name="Master Playback Volume" $VOL > /dev/null
}

alsa_volume_bump(){
  alsa_volume_set $(($MAX_VOL*2/3))
}

alsa_volume_restore(){
   alsa_volume_set $SAVED_VOL
}

if lvs --reportformat json  ${BACKUP_VOLUME}  | jq -r ".report[].lv[].lv_name" | grep -q "${MY_NAME}_backup"
then
  # we've got volume for our backups
  lvchange -a y ${BACKUP_LV}
  mkdir -p ${BACKUP_BASE}
  mount ${BACKUP_DEV} ${BACKUP_BASE}
  ls ${BACKUP_BASE}
  notify_users -t 0 -u critical -c transfer -a "Udev Backup" "Backup initiating" "Udev-based backup is initiating"
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

# alsa_volume_save
# alsa_volume_bump
##XXX device not found errors etc so far...
# aplay -D pulse /etc/backup/finish.wav
# notify_users -c transfer.complete --hint=string:sound-file:/etc/backup/finish.wav -a "Udev Backup" "Backup comlete" "Udev-based backup is complete"
# https://unix.stackexchange.com/questions/251243/what-do-a-notify-send-notification-category-hint-and-version-parameters-mean#381093
notify_users --hint=string:sound-file:/etc/backup/finish.wav -t 0 -u critical -c transfer.complete -a "Udev Backup" "Backup comlete" "Udev-based backup is complete"
# alsa_volume_restore
