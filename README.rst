Inspired by `doozan forum post <https://forum.doozan.com/read.php?2,24139,24244,quote=1>`_

Requirements
============

* ansible
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

Installation
============

Ansible (Recommended)
---------------------

Recommended way would be to generate inventory file (my_inventory)::

  localhost ansible_connection=local udev_rules_dir=/tmp/udev backup_volume_group_name=backup_vg

followed by ansible-playbook invocation::
  
  ansible-playbook -K -i my_inventory install.yml

for uninstall things are just as simple::

  ansible-playbook -K -i my_inventory uninstall.yml

Ansible (not recommended)
-------------------------

More manual process would look more like::

   ansible-playbook -i localhost, -c local -e 'udev_rules_dir=/tmp/udev' -e 'backup_volume_group_name=backup_vg' install.yml

note that for uninstall you'd have to reproduce some of the above options::
  
   ansible-playbook -i localhost, -c local -e 'udev_rules_dir=/tmp/udev' uninstall.yml

which is complicated if you installed software quite a while ago and can't recall all the params.

Manual
------

it is possible to install most components manually. For now just follow ansible playbooks to mimic behavior, however you're loosing jinja templates and nice level of automation ansible brings to the entire process