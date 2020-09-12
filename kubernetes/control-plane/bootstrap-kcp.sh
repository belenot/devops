# Create the Kubernetes configuration directory:
sudo mkdir -p /etc/kubernetes/config

# Download the official Kubernetes release binaries:
# Better download it in on host and then cp for each worker node
#wget -q --show-progress --https-only --timestamping \
#  "https://storage.googleapis.com/kubernetes-release/release/v1.18.6/bin/linux/amd64/kube-apiserver" \
#  "https://storage.googleapis.com/kubernetes-release/release/v1.18.6/bin/linux/amd64/kube-controller-manager" \
#  "https://storage.googleapis.com/kubernetes-release/release/v1.18.6/bin/linux/amd64/kube-scheduler" \
#  "https://storage.googleapis.com/kubernetes-release/release/v1.18.6/bin/linux/amd64/kubectl"
sudo cp /vagrant/control-plane/binaries/* /home/vagrant
# Install the Kubernetes binaries:
chmod +x kube-apiserver kube-controller-manager kube-scheduler kubectl
sudo cp kube-apiserver kube-controller-manager kube-scheduler kubectl /usr/local/bin/

# Configure the Kubernetes API Server
sudo mkdir -p /var/lib/kubernetes/

sudo cp /vagrant/creds/ca.pem /vagrant/creds/ca-key.pem \
/vagrant/creds/kubernetes-key.pem /vagrant/creds/kubernetes.pem \
/vagrant/creds/service-account-key.pem /vagrant/creds/service-account.pem \
/vagrant/creds/encryption-config.yaml /var/lib/kubernetes/

INTERNAL_IP=127.0.0.1

# Create the kube-apiserver.service systemd unit file:
cat <<EOF | sudo tee /etc/systemd/system/kube-apiserver.service
[Unit]
Description=Kubernetes API Server
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-apiserver \\
  --advertise-address=${INTERNAL_IP} \\
  --allow-privileged=true \\
  --apiserver-count=1 \\
  --audit-log-maxage=30 \\
  --audit-log-maxbackup=3 \\
  --audit-log-maxsize=100 \\
  --audit-log-path=/var/log/audit.log \\
  --authorization-mode=Node,RBAC \\
  --bind-address=0.0.0.0 \\
  --client-ca-file=/var/lib/kubernetes/ca.pem \\
  --enable-admission-plugins=NamespaceLifecycle,NodeRestriction,LimitRanger,ServiceAccount,DefaultStorageClass,ResourceQuota \\
  --etcd-cafile=/var/lib/kubernetes/ca.pem \\
  --etcd-certfile=/var/lib/kubernetes/kubernetes.pem \\
  --etcd-keyfile=/var/lib/kubernetes/kubernetes-key.pem \\
  --etcd-servers=https://k8s-master:2379 \\
  --event-ttl=1h \\
  --encryption-provider-config=/var/lib/kubernetes/encryption-config.yaml \\
  --kubelet-certificate-authority=/var/lib/kubernetes/ca.pem \\
  --kubelet-client-certificate=/var/lib/kubernetes/kubernetes.pem \\
  --kubelet-client-key=/var/lib/kubernetes/kubernetes-key.pem \\
  --kubelet-https=true \\
  --runtime-config='api/all=true' \\
  --service-account-key-file=/var/lib/kubernetes/service-account.pem \\
  --service-cluster-ip-range=10.32.0.0/24 \\
  --service-node-port-range=30000-32767 \\
  --tls-cert-file=/var/lib/kubernetes/kubernetes.pem \\
  --tls-private-key-file=/var/lib/kubernetes/kubernetes-key.pem \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# Configure the Kubernetes Controller Manager
# Move the kube-controller-manager kubeconfig into place:
sudo cp /vagrant/creds/kube-controller-manager.kubeconfig /var/lib/kubernetes/

# Create the kube-controller-manager.service systemd unit file:
cat <<EOF | sudo tee /etc/systemd/system/kube-controller-manager.service
[Unit]
Description=Kubernetes Controller Manager
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-controller-manager \\
  --bind-address=0.0.0.0 \\
  --cluster-cidr=10.200.0.0/16 \\
  --cluster-name=kubernetes \\
  --cluster-signing-cert-file=/var/lib/kubernetes/ca.pem \\
  --cluster-signing-key-file=/var/lib/kubernetes/ca-key.pem \\
  --kubeconfig=/var/lib/kubernetes/kube-controller-manager.kubeconfig \\
  --leader-elect=true \\
  --root-ca-file=/var/lib/kubernetes/ca.pem \\
  --service-account-private-key-file=/var/lib/kubernetes/service-account-key.pem \\
  --service-cluster-ip-range=10.32.0.0/24 \\
  --use-service-account-credentials=true \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# Configure the Kubernetes Scheduler
# Move the kube-scheduler kubeconfig into place:
sudo cp /vagrant/creds/kube-scheduler.kubeconfig /var/lib/kubernetes/

# Create the kube-scheduler.yaml configuration file:
cat <<EOF | sudo tee /etc/kubernetes/config/kube-scheduler.yaml
apiVersion: kubescheduler.config.k8s.io/v1alpha1
kind: KubeSchedulerConfiguration
clientConnection:
  kubeconfig: "/var/lib/kubernetes/kube-scheduler.kubeconfig"
leaderElection:
  leaderElect: true
EOF

#Create the kube-scheduler.service systemd unit file:
cat <<EOF | sudo tee /etc/systemd/system/kube-scheduler.service
[Unit]
Description=Kubernetes Scheduler
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-scheduler \\
  --config=/etc/kubernetes/config/kube-scheduler.yaml \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# Start the Controller Services
sudo systemctl daemon-reload
sudo systemctl enable kube-apiserver kube-controller-manager kube-scheduler
sudo systemctl start kube-apiserver kube-controller-manager kube-scheduler

# Enable HTTP Health Checks
sudo apt-get update
sudo apt-get install -y nginx

cat > kubernetes.default.svc.cluster.local <<EOF
server {
  listen      80;
  server_name kubernetes.default.svc.cluster.local;

  location /healthz {
     proxy_pass                    https://127.0.0.1:6443/healthz;
     proxy_ssl_trusted_certificate /var/lib/kubernetes/ca.pem;
  }
}
EOF

sudo cp kubernetes.default.svc.cluster.local \
  /etc/nginx/sites-available/kubernetes.default.svc.cluster.local

sudo ln -s /etc/nginx/sites-available/kubernetes.default.svc.cluster.local /etc/nginx/sites-enabled/

sudo systemctl restart nginx
sudo systemctl enable nginx

cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRole
metadata:
  annotations:
    rbac.authorization.kubernetes.io/autoupdate: "true"
  labels:
    kubernetes.io/bootstrapping: rbac-defaults
  name: system:kube-apiserver-to-kubelet
rules:
  - apiGroups:
      - ""
    resources:
      - nodes/proxy
      - nodes/stats
      - nodes/log
      - nodes/spec
      - nodes/metrics
    verbs:
      - "*"
EOF

cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRoleBinding
metadata:
  name: system:kube-apiserver
  namespace: ""
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:kube-apiserver-to-kubelet
subjects:
  - apiGroup: rbac.authorization.k8s.io
    kind: User
    name: kubernetes
EOF

## Worker nodes

kubectl create clusterrolebinding node-1-admin --clusterrole=cluster-admin --user=node-1
kubectl create clusterrolebinding node-2-admin --clusterrole=cluster-admin --user=node-2
kubectl create clusterrolebinding node-3-admin --clusterrole=cluster-admin --user=node-3
kubectl create clusterrolebinding kube-controller-manager-admin --user=kube-controller-manager --clusterrole=cluster-admin
kubectl create clusterrolebinding kube-scheduler-admin --user=kube-scheduler --clusterrole=cluster-admin
kubectl create clusterrolebinding kube-proxy-admin --user=kube-proxy --clusterrole=cluster-admin

sudo sh -c 'echo "192.168.50.11 node-1" >> /etc/hosts'
sudo sh -c 'echo "192.168.50.12 node-2" >> /etc/hosts'
sudo sh -c 'echo "192.168.50.13 node-3" >> /etc/hosts'