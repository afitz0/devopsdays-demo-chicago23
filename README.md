# Steps to run:

* `minikube start`
* `eval $(minikube -p minikube docker-env)`
* `docker build -t devopsdays/loyalty .`
* `kubectl apply -f k8s-worker.yaml 2>&1 | tee -a k8s-worker.log`
* `./kill_random_worker.sh 2>&1 >> random-term.log &`
* `./random_signaling.sh 2>&1 >> simulated-actions.log &`
