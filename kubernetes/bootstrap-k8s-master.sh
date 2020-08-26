# sudo apt-get install -y \
#   apt-transport-https \
#   ca-certificates \
#   curl \
#   gnupg-agent \
#   software-properties-common

# curl https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

# sudo apt-add-repository --yes https://download.docker.com/linux/ubuntu

# sudo apt-get install docker-ce docker-ce-cli containerd.io

# sudo usermod -aG docker vagrant

# sudo sed -i '/swap/d' /etc/fstab
# sudo swapoff -a

# curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
# sudo apt-add-repository https://apt.kubernetes.io/

# sudo apt-get install -y kubelet kubeadm kubectl
