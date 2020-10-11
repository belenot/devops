tar -xvf /vagrant/binaries/etcd.tar.gz
sudo mv etcd*/etcd* /usr/local/bin/
                                                                                                                                                                             
sudo mkdir -p /etc/etcd /var/lib/etcd
sudo chmod 700 /var/lib/etcd
sudo cp /vagrant/creds/ca-crt.pem /vagrant/creds/kubernetes-key.pem /vagrant/creds/kubernetes-crt.pem /etc/etcd/

INTERNAL_IP=127.0.0.1
ETCD_NAME=$(hostname -s)
#INTERNAL_IP=$ETCD_NAME
#,controller-1=https://10.240.0.11:2380,controller-2=https://10.240.0.12:2380 \\
sudo cp /vagrant/etcd/etcd.service /etc/systemd/system/etcd.service

sudo systemctl daemon-reload
sudo systemctl enable etcd
sudo systemctl start etcd