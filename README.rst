Inspired by `doozan forum post <post: https://forum.doozan.com/read.php?2,24139,24244,quote=1>`_

Requirements
============

* jq
* LVM
* cut
* test ( "[" )
* rsync

Outline
=======

backup_device_probe.sh 
----------------------

assess whether connected device contains required backup volume group

lvm_backup.sh
-------------

within backup volume find volume named <hostname>_backup and if it exists launch backup

using rsync backup data to a timestamped dir. If there was previous backup (symlinked via "current") - it will be used as a base for "delta" backup performed by rsync - all unchanged files will be hard-linked to the originals (implementing simple counter garbage collector in a way) and any new changes added as new files. This way backup size may stay smaller while achieving snapshotting and delta backups.
