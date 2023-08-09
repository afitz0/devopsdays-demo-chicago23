#!/bin/zsh

KILL_EVERY_N_SEC=5

eval $(minikube docker-env)

while true; do
    pod=$(kubectl get pods -l=app=loyalty -o name | sort -R | tail -n 1)
    kubectl delete $pod
    sleep $KILL_EVERY_N_SEC
done
