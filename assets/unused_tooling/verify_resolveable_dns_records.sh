#!/bin/bash

#### Waiting for all masters to be resolveable
trimmed_masters_dns_records=$(echo ${masters_dns_records} | tr -d ,)
for interval in {1..36}
do
    record_resolveable="true"
    for record in $trimmed_masters_dns_records
    do
        getent hosts $record
        echo "for tests output record: $record"
        if [[ $? -ne 0 ]]; then record_resolveable="false"; fi
    done
    if [[ $record_resolveable == "true" ]]; then break; fi
    echo "sleeping, end of interval $interval"
    sleep 10
done