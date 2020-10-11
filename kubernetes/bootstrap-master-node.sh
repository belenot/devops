sudo bash /vagrant/etcd/bootstrap-etcd.sh
sudo sed -i 's/127.[0-9]*.[0-9]*.[0-9]*\(\s*k8s-master\s*k8s-master\)/127.0.0.1\1/g' /etc/hosts
sudo sh /vagrant/control-plane/bootstrap-control-plane.sh