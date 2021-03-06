#!/bin/bash

log_directory=/edx/var/log
reach=$(ntpq -c associations | awk '{print $5}' | grep yes)
if [[ ${reach} == *"no"* ]]; then
    echo $(date -u) $(hostname) "NTPD not synchronized - Please investigate" >> ${log_directory}/ntp.log
fi

limit=100   # limit in milliseconds
offsets=$(ntpq -nc peers | tail -n +3 | cut -c 62-66 | tr -d '-')
for offset in ${offsets}; do
    if [ ${offset:-0} -ge ${limit:-100} ]; then
        echo $(date -u) $(hostname) "An NTPD offset with value $offset is excessive - Please investigate" >> ${log_directory}/ntp.log
        exit 1
    fi
done
