#!/bin/bash

rm /usr/local/bin/results.log

/usr/local/bin/import_storage_data.sh proxmox1.ad110.local 22
/usr/local/bin/import_storage_data.sh proxmox2.ad110.local 22
/usr/local/bin/import_storage_data.sh proxmox3.ad110.local 22

/usr/local/bin/import_storage_data.sh proxmox1.m6.local 22
/usr/local/bin/import_storage_data.sh proxmox2.m6.local 22

/usr/local/bin/import_storage_data.sh proxmox1.libero.local 22
/usr/local/bin/import_storage_data.sh proxmox2.libero.local 22

/usr/local/bin/import_storage_data.sh proxmox1.plus.local 22

/usr/local/bin/import_storage_data.sh proxmox1.figura.local 22

/usr/local/bin/import_storage_data.sh proxmox1.xxxx.com 56022
/usr/local/bin/import_storage_data.sh proxmox2.xxxx.com 56022
/usr/local/bin/import_storage_data.sh proxmox3.xxxx.com 22
/usr/local/bin/import_storage_data.sh proxmox4.xxxx.com 56022

