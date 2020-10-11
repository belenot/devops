sudo mkdir -p /etc/kubernetes/config

sudo chmod +x /vagrant/binaries/kube-apiserver
sudo chmod +x /vagrant/binaries/kube-controller-manager
sudo chmod +x /vagrant/binaries/kube-scheduler
sudo chmod +x /vagrant/binaries/kubectl
sudo cp /vagrant/binaries/kube-apiserver /usr/local/bin/
sudo cp /vagrant/binaries/kube-controller-manager /usr/local/bin/
sudo cp /vagrant/binaries/kube-scheduler /usr/local/bin/
sudo cp /vagrant/binaries/kubectl /usr/local/bin/

sudo mkdir -p /var/lib/kubernetes/

sudo cp /vagrant/creds/ca-crt.pem /vagrant/creds/ca-key.pem \
/vagrant/creds/kubernetes-key.pem /vagrant/creds/kubernetes-crt.pem \
/vagrant/creds/service-account-key.pem /vagrant/creds/service-account-crt.pem \
/vagrant/creds/encryption-config.json /var/lib/kubernetes/

INTERNAL_IP=127.0.0.1

sudo cp /vagrant/control-plane/*.service /etc/systemd/system/
sudo cp /vagrant/creds/kube-controller-manager.kubeconfig /var/lib/kubernetes/
sudo cp /vagrant/creds/kube-scheduler.kubeconfig /var/lib/kubernetes/
sudo cp /vagrant/control-plane/kube-scheduler.yaml  /etc/kubernetes/config/kube-scheduler.yaml

# Start the Controller Services
sudo systemctl daemon-reload
sudo systemctl enable kube-apiserver kube-controller-manager kube-scheduler
sudo systemctl start kube-apiserver kube-controller-manager kube-scheduler

# Enable HTTP Health Checks
sudo apt-get update
sudo apt-get install -y nginx

sudo cp /vagrant/control-plane/kubernetes.default.svc.cluster.local \
        /etc/nginx/sites-available/kubernetes.default.svc.cluster.local

sudo ln -s /etc/nginx/sites-available/kubernetes.default.svc.cluster.local /etc/nginx/sites-enabled/

sudo systemctl restart nginx
sudo systemctl enable nginx

sudo sh -c 'echo "192.168.50.11 node-1" >> /etc/hosts'
sudo sh -c 'echo "192.168.50.12 node-2" >> /etc/hosts'
sudo sh -c 'echo "192.168.50.13 node-3" >> /etc/hosts'

sudo chmod +x /vagrant/control-plane/create-role-bindings.sh
sh -c '/vagrant/control-plane/create-role-bindings.sh'