openssl req -out rootCA.pem -keyout rootCA-key.pem -nodes -new -days 365 -newkey rsa:2048 -x509 -subj "/CN=root"

openssl req -out admin-csr.pem -new -nodes -keyout admin-key.pem -days 365 -subj "/CN=admin" -newkey rsa:2048
openssl x509 -in admin-csr.pem -out admin.pem -days 356 -req -CA rootCA.pem -CAkey rootCA-key.pem

openssl req -out node-1-csr.pem -new -nodes -keyout node-1-key.pem -days 365 -subj "/CN=system:node:node-1" -newkey rsa:2048
openssl x509 -in node-1-csr.pem -out node-1.pem -days 356 -req -CA rootCA.pem -CAkey rootCA-key.pem

openssl req -out node-2-csr.pem -new -nodes -keyout node-2-key.pem -days 365 -subj "/CN=system:node:node-2" -newkey rsa:2048
openssl x509 -in node-2-csr.pem -out node-2.pem -days 356 -req -CA rootCA.pem -CAkey rootCA-key.pem

openssl req -out node-3-csr.pem -new -nodes -keyout node-3-key.pem -days 365 -subj "/CN=system:node:node-3" -newkey rsa:2048
openssl x509 -in node-3-csr.pem -out node-3.pem -days 356 -req -CA rootCA.pem -CAkey rootCA-key.pem

openssl req -out kube-controller-manager-csr.pem -new -nodes -keyout kube-controller-manager-key.pem -days 365 -subj "/CN=system:kube-controller-manager" -newkey rsa:2048
openssl x509 -in kube-controller-manager-csr.pem -out kube-controller-manager.pem -days 356 -req -CA rootCA.pem -CAkey rootCA-key.pem

openssl req -out kube-proxy-csr.pem -new -nodes -keyout kube-proxy-key.pem -days 365 -subj "/CN=system:kube-proxy" -newkey rsa:2048
openssl x509 -in kube-proxy-csr.pem -out kube-proxy.pem -days 356 -req -CA rootCA.pem -CAkey rootCA-key.pem

openssl req -out kube-scheduler-csr.pem -new -nodes -keyout kube-scheduler-key.pem -days 365 -subj "/CN=system:kube-scheduler" -newkey rsa:2048
openssl x509 -in kube-scheduler-csr.pem -out kube-scheduler.pem -days 356 -req -CA rootCA.pem -CAkey rootCA-key.pem

openssl req -out kubernetes-csr.pem -new -nodes -keyout kubernetes-key.pem -days 365 -subj "/CN=system:kubernetes" -newkey rsa:2048
openssl x509 -in kubernetes-csr.pem -out kubernetes.pem -days 356 -req -CA rootCA.pem -CAkey rootCA-key.pem

openssl req -out service-account-csr.pem -new -nodes -keyout service-account-key.pem -days 365 -subj "/CN=service-account" -newkey rsa:2048
openssl x509 -in service-account-csr.pem -out service-account.pem -days 356 -req -CA rootCA.pem -CAkey rootCA-key.pem
