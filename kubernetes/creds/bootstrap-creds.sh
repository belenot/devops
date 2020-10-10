ls | grep -v '\.conf$\|\.sh$'   | xargs rm -rf
touch database.txt && echo 'unique_subject=yes' > database.txt.attr && echo 1000 > serial.txt

# Create root ca
CN=belenot ALTNAMES='DNS:belenot' openssl req -config openssl.conf -new -x509 -keyout ca-key.pem > ca-crt.pem

export indexes=( 0 1 2 3 4 5 6 7 8 )
#export names=( admin node-1 node-2 node-3 kube-controller-manager kube-proxy kube-scheduler kubernetes service-account )
export names=( admin node-1 node-2 node-3 kube-controller-manager kube-proxy kube-scheduler kubernetes service-account )
export altnames=( 'DNS:system:masters,DNS:k8s-master' \
'DNS:system:node:node-1,DNS:node-1' \
'DNS:system:node:node-2,DNS:node-2' \
'DNS:system:node:node-3,DNS:node-3' \
'DNS:kube-controller-manager,DNS:k8s-master' \
'DNS:kube-proxy' \
'DNS:kube-scheduler,DNS:k8s-master' \
'DNS:kubernetes,DNS:k8s-master' \
'DNS:service-account' \
)
for i in ${indexes[@]}; do
  echo "FOR CN=${names[i]} ALTNAMES=${altnames[i]}"
  CN="${names[i]}" ALTNAMES="${altnames[i]}" openssl req -config openssl.conf -new > ${names[i]}-csr.pem
  CN="${names[i]}" ALTNAMES="${altnames[i]}" openssl ca -config openssl.conf -batch -in ${names[i]}-csr.pem > ${names[i]}.pem
done



KUBERNETES_PUBLIC_ADDRESS=k8s-master


for instance in node-1 node-2 node-3; do 
		kubectl config set-cluster kubernetes-devops \
						--certificate-authority=ca-crt.pem \
						--embed-certs=true \
						--server=https://${KUBERNETES_PUBLIC_ADDRESS}:6443 \
						--kubeconfig=${instance}.kubeconfig


		kubectl config set-credentials system:node:${instance} \
						--client-certificate=${instance}.pem \
						--client-key=${instance}-key.pem \
						--embed-certs=true \
						--kubeconfig=${instance}.kubeconfig

		kubectl config set-context default \
						--cluster=kubernetes-devops \
						--user=system:node:${instance} \
						--kubeconfig=${instance}.kubeconfig

		kubectl config use-context default --kubeconfig=${instance}.kubeconfig
done

{
		kubectl config set-cluster kubernetes-devops \
						--certificate-authority=ca-crt.pem \
						--embed-certs=true \
						--server=https://${KUBERNETES_PUBLIC_ADDRESS}:6443 \
						--kubeconfig=kube-proxy.kubeconfig

		kubectl config set-credentials system:kube-proxy \
						--client-certificate=kube-proxy.pem \
						--client-key=kube-proxy-key.pem \
						--embed-certs=true \
						--kubeconfig=kube-proxy.kubeconfig

		kubectl config set-context default \
						--cluster=kubernetes-devops \
						--user=system:kube-proxy \
						--kubeconfig=kube-proxy.kubeconfig

		kubectl config use-context default --kubeconfig=kube-proxy.kubeconfig
}

{
		kubectl config set-cluster kubernetes-devops \
						--certificate-authority=ca-crt.pem \
						--embed-certs=true \
						--server=https://${KUBERNETES_PUBLIC_ADDRESS}:6443 \
						--kubeconfig=kube-controller-manager.kubeconfig

		kubectl config set-credentials system:kube-controller-manager \
						--client-certificate=kube-controller-manager.pem \
						--client-key=kube-controller-manager-key.pem \
						--embed-certs=true \
						--kubeconfig=kube-controller-manager.kubeconfig

		kubectl config set-context default \
						--cluster=kubernetes-devops \
						--user=system:kube-controller-manager \
						--kubeconfig=kube-controller-manager.kubeconfig

		kubectl config use-context default --kubeconfig=kube-controller-manager.kubeconfig
}

{
		kubectl config set-cluster kubernetes-devops \
						--certificate-authority=ca-crt.pem \
						--embed-certs=true \
						--server=https://${KUBERNETES_PUBLIC_ADDRESS}:6443 \
						--kubeconfig=kube-scheduler.kubeconfig

		kubectl config set-credentials system:kube-scheduler \
						--client-certificate=kube-scheduler.pem \
						--client-key=kube-scheduler-key.pem \
						--embed-certs=true \
						--kubeconfig=kube-scheduler.kubeconfig

		kubectl config set-context default \
						--cluster=kubernetes-devops \
						--user=system:kube-scheduler \
						--kubeconfig=kube-scheduler.kubeconfig

		kubectl config use-context default --kubeconfig=kube-scheduler.kubeconfig
}

{
		kubectl config set-cluster kubernetes-devops \
						--certificate-authority=ca-crt.pem \
						--embed-certs=true \
						--server=https://${KUBERNETES_PUBLIC_ADDRESS}:6443 \
						--kubeconfig=admin.kubeconfig

		kubectl config set-credentials admin \
						--client-certificate=admin.pem \
						--client-key=admin-key.pem \
						--embed-certs=true \
						--kubeconfig=admin.kubeconfig

		kubectl config set-context default \
						--cluster=kubernetes-devops \
						--user=admin \
						--kubeconfig=admin.kubeconfig

		kubectl config use-context default --kubeconfig=admin.kubeconfig
}
ENCRYPTION_KEY=`head -c 32 /dev/urandom | base64`

cat > encryption-config.yaml <<EOF
kind: EncryptionConfig
apiVersion: v1
resources:
- resources:
  - secrets
  providers:
  - aescbc:
      keys:
      - name: key1
        secret: ${ENCRYPTION_KEY}
  - identity: {}
EOF
