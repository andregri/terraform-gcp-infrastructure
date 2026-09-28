# Kubeadm cluster

Delete lines from ssh known hosts with previous fingerprints:
```bash
sed -i "" "/^control-plane0/d" "$HOME/.ssh/known_hosts"
sed -i "" "/^worker0/d" "$HOME/.ssh/known_hosts"
```

Ping the hosts:
```bash
ansible -m ping -i kubeadm-cluster/inventory.yaml all
```

Debug the metadata_startup_script:
```
ansible -m shell -i kubeadm-cluster/inventory.yaml control-plane0 -a "sudo journalctl --no-pager -u google-startup-scripts.service"
ansible -m shell -i kubeadm-cluster/inventory.yaml control-plane0 -a "kubeadm version"
ansible -m shell -i kubeadm-cluster/inventory.yaml control-plane0 -a "kubectl get nodes"
ansible -m shell -i kubeadm-cluster/inventory.yaml control-plane0 -a "kubectl get svc -A"
ansible -m shell -i kubeadm-cluster/inventory.yaml control-plane0 -a "kubectl get pods -A"
ansible -m shell -i kubeadm-cluster/inventory.yaml control-plane0 -a "kubectl run dns-test --image=busybox:1.36 --rm -it --restart=Never -- nslookup kubernetes.default.svc.cluster.local"
```

Run ansible playbooks:
```bash
ansible-playbook -i kubeadm-cluster/inventory.yaml path/to/playbook.yaml
```

Example:
```bash
# init kubeadm cluster
ansible-playbook -i kubeadm-cluster/inventory.yaml  /Users/andreagrillo/Downloads/github-personal/ansible-roles/playbooks/kubeadm-cluster/kubeadm-playbook.yaml