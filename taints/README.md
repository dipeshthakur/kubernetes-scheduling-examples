Taints and Tolerations

Taints can be used for advanced scheduling in kubernetes. Tutorial below is a walk through of such usage.
Concepts
Taints

Taint is a property of node that allows you to repel a set of pods unless those pods explicitly tolerates the said taint.

Taint has three parts. A key, a value and an effect.

For example,

kubectl taint nodes worker1 thisnode=hatesPods:NoSchedule

The above taint has key=thisnode, value=HatesPods and effect as NoSchedule. These key value pairs are configurable. Any pod that doesn't have a matching toleration to this taint will not be scheduled on worker1.

To remove the above taint, we can run the following command

kubectl taint nodes worker1  thisnode:NoSchedule-

What are some of the Taint effects?

    NoSchedule - Doesn't schedule a pod without matching tolerations
    PreferNoSchedule - Prefers that the pod without matching toleration be not scheduled on the node. It is a softer version of NoSchedule effect.
    NoExecute - Evicts the pods that don't have matching tolerations.

A node can have multiple taints. For example, if any pod is to be scheduled on a node with multiple NoExecute effect taints, then that pod must tolerate all the taints. However, if the set of taints on a node is a combination of NoExecute and PreferNoExecute effects and the pod only tolerates NoExecute taints then kubernetes will prefer not to schedule the pod on that node, but will do it anyway if there's no alternative.
Tolerations

Nodes are tainted for a simple reason, to avoid running of workload. The similar outcome can be achieved by PodAffinity/PodAnti-Affinity, however, to reject a large workload taints are more efficient (In a sense that they only require tolerations to be added to the small workload that does run on the tainted nodes as opposed to podAffinity which would require every pod template to carry that information)

Toleration is simply a way to overcome a taint.

For example, In the above section, we have tainted thisnode.compute.infracloud.io

To schedule the pod on that node, we need a matching toleration. Below is the toleration that can be used to overcome the taint.

tolerations:
- key: "thisnode"
  operator: "Equal"
  value: "HatesPods"
  effect: "NoSchedule"

What we are telling kubernetes here is that, on any node if you find that there's a taint with key node1 and its value is HatesPods then that particular taint should not stop you from scheduling this pod on that node.

Toleration generally has four parts. A key, a value, an operator and an effect. Operator, if not specified, defaults to Equal
Use cases

    Taints can be used to group together a set of Nodes that only run a certain set of workload, like network pods or pods with special resource requirement.
    Taints can also be used to evict a large set of pods from a node using taint with NoExecute effect.

Examples:

Follow through guide.

Let's begin with listing nodes.

kubectl get nodes

You should be able to see the list of nodes available in the cluster,

NAME               STATUS   ROLES                  AGE     VERSION
master1.sipl.com   Ready    control-plane,master   5d23h   v1.22.4
worker1            Ready    <none>                 5d22h   v1.22.4
worker2.sipl.com   Ready    <none>                 5d22h   v1.22.4

Now, let's taint node1 with NoSchedule effect.

kubectl taint nodes worker1 thisnode=hatesPods:NoSchedule

You should be able to see that node1 is now tainted.

node/worker1 tainted

Let's run the deployment to see where pods are deployed.

kubectl create -f deployment.yaml

Check the output using,

kubectl get pods -o wide

You should be able that the pods aren't scheduled on worker1

NAME                                READY   STATUS    RESTARTS   AGE   IP            NODE               NOMINATED NODE   READINESS GATES
nginx-deployment-5d59d67564-29xv4   1/1     Running   0          13s   10.244.2.10   worker2.sipl.com   <none>           <none>
nginx-deployment-5d59d67564-8k9rp   1/1     Running   0          13s   10.244.2.12   worker2.sipl.com   <none>           <none>
nginx-deployment-5d59d67564-l5qh4   1/1     Running   0          13s   10.244.2.11   worker2.sipl.com   <none>           <none>


Now let's taint node3 with NoExecute effect, which will evict the pods from node3 and schedule them on node2.

kubectl taint nodes worker2.sipl.com  thisnode=AlsoHatesPods:NoExecute

In a few seconds you'll see that the pods are terminated or pending on worker2 and if it is another third node will spawned on node3

NAME                                READY   STATUS    RESTARTS   AGE   IP       NODE     NOMINATED NODE   READINESS GATES
nginx-deployment-5d59d67564-6nh5w   0/1     Pending   0          18s   <none>   <none>   <none>           <none>
nginx-deployment-5d59d67564-9w7lg   0/1     Pending   0          18s   <none>   <none>   <none>           <none>
nginx-deployment-5d59d67564-pf9w9   0/1     Pending   0          18s   <none>   <none>   <none>           <none>

The above example demonstrates taint based evictions.

Let's delete the deployment and create new one with tolerations for the above taints.

kubectl delete deployment nginx-deployment

kubectl create -f deployment-toleration.yaml

You can check the output by running,

kubectl get pods -o wide

You should be able to see that some of the pods are scheduled on worker1 and some on master1. However, no pod is scheduled on worker2. This is because, in the new deployment spec, we are tolerating taint NoSchedule effect. worker2 is tainted with NoExecute effect which we have not tolerated so no pods will be scheduled there.


NAME                                READY   STATUS    RESTARTS   AGE     IP            NODE               NOMINATED NODE   READINESS GATES
nginx-deployment-7888b4f987-7crdp   1/1     Running   0          4m14s   10.244.0.9    master1.sipl.com   <none>           <none>
nginx-deployment-7888b4f987-7grvt   1/1     Running   0          4m14s   10.244.0.7    master1.sipl.com   <none>           <none>
nginx-deployment-7888b4f987-cghdp   1/1     Running   0          4m14s   10.244.0.6    master1.sipl.com   <none>           <none>
nginx-deployment-7888b4f987-grgqq   1/1     Running   0          4m14s   10.244.1.12   worker1            <none>           <none>
nginx-deployment-7888b4f987-nvff8   1/1     Running   0          4m14s   10.244.1.17   worker1            <none>           <none>
nginx-deployment-7888b4f987-rgv2r   1/1     Running   0          4m14s   10.244.1.14   worker1            <none>           <none>
nginx-deployment-7888b4f987-wtjcq   1/1     Running   0          4m14s   10.244.0.8    master1.sipl.com   <none>           <none>
nginx-deployment-7888b4f987-wwbf2   1/1     Running   0          4m14s   10.244.1.16   worker1            <none>           <none>
nginx-deployment-7888b4f987-x88dr   1/1     Running   0          4m14s   10.244.1.13   worker1            <none>           <none>
nginx-deployment-7888b4f987-zqvdf   1/1     Running   0          4m14s   10.244.1.15   worker1            <none>           <none>

To finish off, let's remove the taints from the nodes,

kubectl taint nodes worker2.sipl.com thisnode:NoExecute-

node/worker2.sipl.com untainted


kubectl taint nodes worker1 thisnode:NoSchedule-

node/worker1 untainted





