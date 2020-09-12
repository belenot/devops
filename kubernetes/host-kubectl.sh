  # add k8s-master to /etc/hosts
  
  KUBERNETES_PUBLIC_ADDRESS=k8s-master

  kubectl config set-cluster kubernetes \
    --certificate-authority=creds/ca.pem \
    --embed-certs=true \
    --server=https://${KUBERNETES_PUBLIC_ADDRESS}:6443

  kubectl config set-credentials admin \
    --client-certificate=creds/admin.pem \
    --client-key=creds/admin-key.pem

  kubectl config set-context kubernetes \
    --cluster=kubernetes \
    --user=admin

  kubectl config use-context kubernetes