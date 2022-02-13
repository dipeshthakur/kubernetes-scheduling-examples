set -x

kubectl apply -f playbook/redis-master-deployment.yaml
sleep 15
kubectl apply -f playbook/redis-master-service.yaml

kubectl apply -f playbook/redis-slave-deployment.yaml
sleep 30
kubectl apply -f playbook/redis-slave-service.yaml

kubectl apply -f playbook/frontend-deployment.yaml
sleep 45
kubectl apply -f playbook/frontend-service.yaml

kubectl get pods -o wide

kubectl describe service frontend | grep "LoadBalancer Ingress"
