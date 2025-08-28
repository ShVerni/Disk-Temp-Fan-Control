#!/bin/bash

# Based on https://github.com/kowalcj0/TrueNAS-Scale-scripts/blob/master/get_hdd_temp.sh

# See https://sharats.me/posts/shell-script-best-practices/
set -o errexit
set -o nounset
set -o pipefail
if [[ "${TRACE-0}" == "1" ]]; then
  set -o xtrace
fi

# Full path to 'smartctl' program:
smartctl=$(which smartctl)

# Choose one of the following two methods to specify the drives you want to monitor:

# 1. A string constant; just key in the devices you want to report on here:
drives="/dev/sda /dev/sdb /dev/sdc"

# 2. A smartctl-based function:

get_smart_drives()
{
  gs_smartdrives=""
  gs_drives=$("${smartctl}" --scan | awk '{print $1}')

  for gs_drive in ${gs_drives}; do
    gs_smart_flag=$("${smartctl}" -i "${gs_drive}" | egrep "SMART support is:[[:blank:]]+Enabled" | awk '{print $4}')
    if [ "$gs_smart_flag" = "Enabled" ]; then
      gs_smartdrives="${gs_smartdrives} ${gs_drive}"
    fi
  done
  #echo "${gs_smartdrives}"
}

# Uncomment the next line to use the function to get the drives:
#drives=$(get_smart_drives)


#############################
# Drive temperatures:
#############################

#echo "=== DRIVES ==="
while :
do
  hottest=0
  for drive in ${drives}; do
    temp=$("${smartctl}" -A "${drive}" | grep "194 Temperature" | awk '{print $10}')
    if [ -z "${temp}" ]; then
      temp=$("${smartctl}" -A "${drive}" | grep "190 Temperature_Case" | awk '{print $10}')
    fi
    if [ -z "${temp}" ]; then
      temp=$("${smartctl}" -A "${drive}" | grep "190 Airflow_Temperature" | awk '{print $10}')
    fi
    if [ -z "${temp}" ]; then
      temp=$("${smartctl}" -A "${drive}" | grep "Current Drive Temperature" | awk '{print $4}')
    fi
    if [ -z "${temp}" ]; then
      temp="0"
    fi
    # echo "$drive": "$temp"
    # if [ $(("temp")) -gt "$hottest" ]; then # Alternative POSIX-like syntax
    if (($(("temp")) > "$hottest")); then
      hottest=$(("temp"))
    fi
  done
  #echo Hottest "$hottest"
  pwm=32
  if (("$hottest" > 47))
  then
    pwm=255
  elif (("$hottest" > 34))
  then
    pwm=$( awk "BEGIN { printf(\"%.0f\", 18.5833 * ${hottest} - 618.4167)}")
  fi
  #echo PWM "$pwm"
  curl "http://Fabrica:Fabrica@fanhub.local/actors/add?actorName=fancontrol&actionID=1&payload=${pwm}" > /dev/null 2>&1
  sleep 10
done
