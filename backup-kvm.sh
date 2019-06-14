#!/bin/bash

REPOSITORY=/firewire/backup/kvm
LIBVIRT_DIRS='/var/lib/libvirt'

# Source BORG_PASSPHRASE
source ./borg-setenv.sh

# Shutdown all kvmguests
./kvmguests.sh stop

# Launch Backup
borg create -v --stats --progress --compression zstd \
    $REPOSITORY::'{now:%Y-%m-%d}'    \
    $LIBVIRT_DIRS

# Use the `prune` subcommand to maintain 7 daily, 4 weekly and 6 monthly
# archives of THIS machine. The '{hostname}-' prefix is very important to
# limit prune's operation to this machine's archives and not apply to
# other machine's archives also.
borg prune -v --list $REPOSITORY \
    --keep-daily=7 --keep-weekly=4 --keep-monthly=6

# borg delete $REPOSITORY::'{hostname}-'2017-06-18
