# Steps to run:

* `minikube start`
* `eval $(minikube -p minikube docker-env)`
* `docker build -t devopsdays/loyalty app/`
* `kubectl apply -f k8s-worker.yaml 2>&1 | tee -a logs/k8s-worker.log`
* `./scripts/chaos.sh 2>&1 | tee -a logs/random-term.log`
* `./scripts/simulate_load.sh 2>&1 | tee -a logs/simulated-actions.log`
