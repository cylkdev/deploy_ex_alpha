#! /usr/bin/env bash

# ------------------------------------------------------------------------------
# Script Name   : user_data.sh
# Description   :
#                 This script ensures the instance is configured to handle its
#                 storage requirements seamlessly and reliably in alignment
#                 with AWS best practices.
#
#                 New EBS volumes attached to an EC2 instance are unformatted
#                 by default. This script formats the volume with the XFS
#                 file system and mounts the volume so that the storage is
#                 accessible to applications and users.
#
#                 When the EC2 instance is rebooted, the mounted volume would
#                 not automatically reattach without configuration. This
#                 script ensure the volume is automatically mounted during
#                 future reboots.
#
# Author(s)     : Kurt Hogarth <kurt@learn-elixir.dev>, Mika Kalathil <mika@learn-elixir.dev>
# Version       : 0.1.0
# Last Updated  : 2024-12-23
# Changelog     :
#                v0.1.0 - Initial version
# License       : MIT
# ------------------------------------------------------------------------------

# Check the file system type of the device /dev/sdh using the file command.
sudo file -s /dev/sdh &&
# If successful, Update the package lists for apt, ensuring the latest package versions are fetched.
sudo apt-get update -y &&
# Install the xfsprogs package, which provides tools for managing XFS file systems.
sudo apt-get install xfsprogs -y &&
# Format the /dev/sdh device with an XFS file system.
sudo mkfs -t xfs /dev/sdh

# Create the directory /data, ensuring parent directories are created if necessary (-p).
sudo mkdir -p /data &&
# Mount the /dev/sdh device to the /data directory.
sudo mount /dev/sdh /data &&
# Retrieve the UUID of the device mounted at /data.
DATA_DEVICE_UUID=$(sudo lsblk -o +UUID | grep /data |  awk '{print $8}')

# Check if DATA_DEVICE_UUID is empty (-z).
# If it is, proceed with the block inside the if, otherwise exit.
if [[ -z $DATA_DEVICE_UUID ]]; then
  # Append an entry to /etc/fstab to persist the mount
  sudo echo "UUID=$DATA_DEVICE_UUID /data  xfs  defaults,nofail  0  2" >> /etc/fstab

  # Unmount /data and remounts all file systems listed in /etc/fstab to apply the new entry.
  sudo umount /data && sudo mount -a
else
  # Exit the script with a status code of 1 indicating an error
  exit 1
fi
