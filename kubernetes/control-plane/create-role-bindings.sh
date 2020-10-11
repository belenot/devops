#kubectl apply -f kube-apiserver-to-kubelet-clusterrole.yaml
#kubectl apply -f kube-apiserver-to-kubelet-clusterrolebinding.yaml

kubectl create clusterrolebinding kubernetes-admin --clusterrole=cluster-admin --user=kubernetes
kubectl create clusterrolebinding node-1-admin --clusterrole=cluster-admin --user=node-1
kubectl create clusterrolebinding node-2-admin --clusterrole=cluster-admin --user=node-2
kubectl create clusterrolebinding node-3-admin --clusterrole=cluster-admin --user=node-3
kubectl create clusterrolebinding kube-controller-manager-admin --user=kube-controller-manager --clusterrole=cluster-admin
kubectl create clusterrolebinding kube-scheduler-admin --user=kube-scheduler --clusterrole=cluster-admin
kubectl create clusterrolebinding kube-proxy-admin --user=kube-proxy --clusterrole=cluster-admin