#!/bin/bash

if pgrep -f "drive_temp_hook.sh" > /dev/null
then
  #echo "Running"
  exit 0
else
  sudo nohup /mnt/bulk/scripts/drive_temp_hook.sh &
  exit 0
fi
exit 0
