# Kubeadm cluster

Requirements:
```bash
brew install cfssl
```

Delete lines from ssh known hosts with previous fingerprints:
```bash
sed -i "" "/^control-plane0/d" "$HOME/.ssh/known_hosts"
sed -i "" "/^worker0/d" "$HOME/.ssh/known_hosts"
sed -i "" "/^etcd0/d" "$HOME/.ssh/known_hosts"
```

Ping the hosts:
```bash
ansible -m ping -i kubeadm-cluster/inventory.yaml all
```

Debug the metadata_startup_script:
```bash
ansible -m shell -i kubeadm-cluster/inventory.yaml control-plane0 -a "sudo journalctl --no-pager -u google-startup-scripts.service"
```

Other debug commands:
```bash
ansible -m shell -i kubeadm-cluster/inventory.yaml control-plane0 -a "kubeadm version"
ansible -m shell -i kubeadm-cluster/inventory.yaml control-plane0 -a "kubectl get nodes"
ansible -m shell -i kubeadm-cluster/inventory.yaml control-plane0 -a "kubectl get svc -A"
ansible -m shell -i kubeadm-cluster/inventory.yaml control-plane0 -a "kubectl get pods -A"
ansible -m shell -i kubeadm-cluster/inventory.yaml control-plane0 -a "kubectl run dns-test --image=busybox:1.36 --rm -it --restart=Never -- nslookup kubernetes.default.svc.cluster.local"
```

Debug the etcd node:
```bash
ansible -i kubeadm-cluster/inventory.yaml etcd0 --become --module-name include_role --args name=/Users/andreagrillo/Downloads/github-personal/ansible-roles/roles/etcd
ansible -m shell -i kubeadm-cluster/inventory.yaml etcd0 -a "etcd --version"
ansible -m shell -i kubeadm-cluster/inventory.yaml etcd0 -a "etcdctl version"
ansible -m shell -i kubeadm-cluster/inventory.yaml etcd0 -a "etcdutl version"
ansible -m shell -i kubeadm-cluster/inventory.yaml etcd0 -a "ls /usr/local/bin/etcd"
ansible -m shell -i kubeadm-cluster/inventory.yaml etcd0 -a "ls /usr/local/bin"
ansible -m shell -i kubeadm-cluster/inventory.yaml etcd0 -a "ls /tmp"
```

Debug etcd systemd:
```bash
sudo systemctl cat etcd
sudo systemd-analyze verify /etc/systemd/system/etcd.service
sudo journalctl --no-pager -u etcd.service
```

Run ansible playbooks:
```bash
ansible-playbook -i kubeadm-cluster/inventory.yaml path/to/playbook.yaml
```

Example to init a kubeadm cluster:
```bash
# init etcd cluster
ansible-playbook -i kubeadm-cluster/inventory.yaml -e "base_path=$(pwd)/kubeadm-cluster" /Users/andreagrillo/Downloads/github-personal/ansible-roles/playbooks/etcd/cluster-playbook.yaml

# init kubeadm cluster
ansible-playbook -i kubeadm-cluster/inventory.yaml /Users/andreagrillo/Downloads/github-personal/ansible-roles/playbooks/kubeadm-cluster/kubeadm-playbook.yaml
```