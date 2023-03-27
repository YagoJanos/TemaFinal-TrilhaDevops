#!/bin/bash

while true; do
    metricbeat setup -E setup.kibana.host=http://172.31.16.8:5601 -E output.elasticsearch.hosts=["http://172.31.16.8:9200"]
    if [ $? -eq 0 ]; then
        touch /var/run/metricbeat-setup-success
        break
    fi
    sleep 10
done

