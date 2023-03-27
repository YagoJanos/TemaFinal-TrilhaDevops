#!/bin/bash
minikube start --static-ip 192.168.49.2

if [ $? -eq 0 ]; then
  minikube kubectl -- apply -f /home/ec2-user/files/kubernetes/elastic-pv.yaml
  minikube kubectl -- apply -f /home/ec2-user/files/kubernetes/elastic-statefulset.yaml
  minikube kubectl -- apply -f /home/ec2-user/files/kubernetes/kibana.yaml
  minikube kubectl -- apply -f /home/ec2-user/files/kubernetes/apm-server.yaml
else
  echo "Minikube start failed. Skipping kubectl apply."
fi
