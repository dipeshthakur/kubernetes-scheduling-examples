set x

kubectl delete -f playbook/redis-master-deployment.yaml
kubectl delete -f playbook/redis-master-service.yaml

kubectl delete -f playbook/redis-slave-deployment.yaml
kubectl delete -f playbook/redis-slave-service.yaml

kubectl delete -f playbook/frontend-deployment.yaml
kubectl delete -f playbook/frontend-service.yaml
