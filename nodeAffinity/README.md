Node Affinity

Node affinity can be used for advanced scheduling in kubernetes. Tutorial below is a walk through of such usage.
Concepts
Node Affinity

    Node affinity is a way to set rules based on which the scheduler can select the nodes for scheduling workload. Node affinity can be thought of as opposite of taints. Taints repel a certain set of nodes where as node affinity attract a certain set of nodes.

    NodeAffinity is a generalization of nodeSelector. In nodeSelector, we specifically mention which node the pod should go to, using node affinity we specify certain rules to select nodes on which pod can be scheduled.

    These rules are defined by labeling the nodes and having pod spec specify the selectors to match those labels. There are 2 types of affinity rules. Preferred rules and Required rules.

    In Preferred rule, a pod will be assigned on a non matching node if and only if no other node in the cluster matches the specified labels. preferredDuringSchedulingIgnoredDuringExecution is a preferred rule affinity.

    In Required rules, if there are no matching nodes, then the pod won't be scheduled. There are a couple of require rule affinities namely requiredDuringSchedulingIgnoredDuringExecution and requiredDuringSchedulingRequiredDuringExecution.

    In requiredDuringSchedulingIgnoredDuringExecution affinity, a pod will be scheduled only if the node labels specified in the pod spec matches with the labels on the node. However, once the pod is scheduled, labels are ignored meaning even if the node labels change, the pod will continue to run on that node.

    In requiredDuringSchedulingRequiredDuringExecution affinity, a pod will be scheduled only if the node labels specified in the pod spec matches with the labels on the node and if the labels on the node change in future, the pod will be evicted. This effect is similar to NoExecute taint with one significant difference. When NoExecute taint is applied on a node, every pod not having a toleration will be evicted, where as, removing/changing a label will remove only the pods that do specify a different label.

Use cases

    While scheduling workload, when we need to schedule a certain set of pods on a certain set of nodes but do not want those nodes to reject everything else, using node affinity makes sense.

Examples:

Follow through guide.

Let's begin with listing nodes.

kubectl get nodes

You should be able to see the list of nodes available in the cluster,

NAME               STATUS   ROLES                  AGE     VERSION
master1.sipl.com   Ready    control-plane,master   5d22h   v1.22.4
worker1            Ready    <none>                 5d22h   v1.22.4
worker2.sipl.com   Ready    <none>                 5d22h   v1.22.4


NodeAffinity works on label matching. Let's label node1 as,

kubectl label nodes worker1 worker1=TheChosenOne

Make sure that you are able to see this label applied to the node,

kubectl get nodes --show-labels | grep TheChosenOne

Now let's try to deploy the entire playbook on the node1. In all the deployment yaml files, a NodeAffinity for node1 is added as,

      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: "worker1"
                operator: In
                values: ["TheChosenOne"]

playbook_create.sh deploys the playbook. Run it as,

./playbook_create.sh

In a couple of minutes, you should be able to see that all the pods are scheduled on node1.

dipesh@master1:~/kube-cluster/kubernetes/kubernetes-scheduling-examples/nodeAffinity$ kubectl get pods -o wide
NAME                           READY   STATUS    RESTARTS   AGE   IP            NODE               NOMINATED NODE   READINESS GATES
frontend-d4648564-2s5zc        1/1     Running   0          15m   10.244.1.9    worker1            <none>           <none>
frontend-d4648564-rqrqg        1/1     Running   0          15m   10.244.1.10   worker1            <none>           <none>
frontend-d4648564-w6mk7        1/1     Running   0          15m   10.244.1.8    worker1            <none>           <none>
nginx-6799fc88d8-fn7tf         1/1     Running   0          37m   10.244.2.2    worker2.sipl.com   <none>           <none>
redis-master-b4457785-gj554    1/1     Running   0          16m   10.244.1.5    worker1            <none>           <none>
redis-slave-7f796bd6f5-gm7fr   1/1     Running   0          15m   10.244.1.6    worker1            <none>           <none>
redis-slave-7f796bd6f5-nm9m9   1/1     Running   0          15m   10.244.1.7    worker1            <none>           <none>


The output will also yield a load balancer ingress url which can be used to load the playbook.

To finish off, let's use playbook_cleanup.sh to remove the playbook.

./playbook_cleanup.sh

