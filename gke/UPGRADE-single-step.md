# Upgrade a GKE cluster

Export common variables:
```bash
export NODE_POOL_NAME=default-pool
export CLUSTER_NAME=lab
export VERSION=1.35.6-gke.1250000
export CONTROL_PLANE_LOCATION=us-central1-c
export ZONE=us-central1-c
```

## kubent

Run kubent to detect API deprecation:
```bash
kubent --target-version 1.35.0
```

example output:
```bash
4:36PM INF >>> Kube No Trouble `kubent` <<<
4:36PM INF version 0.7.3 (git sha 57480c07b3f91238f12a35d0ec88d9368aae99aa)
4:36PM INF Initializing collectors and retrieving data
4:36PM INF Target K8s version is 1.35.0
4:36PM INF Retrieved 0 resources from collector name=Cluster
4:36PM INF Retrieved 0 resources from collector name="Helm v3"
4:36PM INF Loaded ruleset name=custom.rego.tmpl
4:36PM INF Loaded ruleset name=deprecated-1-16.rego
4:36PM INF Loaded ruleset name=deprecated-1-22.rego
4:36PM INF Loaded ruleset name=deprecated-1-25.rego
4:36PM INF Loaded ruleset name=deprecated-1-26.rego
4:36PM INF Loaded ruleset name=deprecated-1-27.rego
4:36PM INF Loaded ruleset name=deprecated-1-29.rego
4:36PM INF Loaded ruleset name=deprecated-1-32.rego
4:36PM INF Loaded ruleset name=deprecated-future.rego
```

## explore gcloud audit logs
Go to gcloud web console > Monitoring > Log Explorer.

Enter the following search query ([gcp docs](https://docs.cloud.google.com/kubernetes-engine/docs/deprecations/apis-1-27?hl=it#location-api-clients-deprecated-apis-write-calls)):
```
resource.type="k8s_cluster"
labels."k8s.io/removed-release"="1.35"
protoPayload.authenticationInfo.principalEmail:("system:serviceaccount" OR "@")
protoPayload.authenticationInfo.principalEmail!~("system:serviceaccount:kube-system:")
```

## Check resources

check cluster resource utils:
```bash
kubectl top nodes
kubectl top pods --all-namespaces
```

check for critical workloads:
```bash
kubectl get deployments --all-namespaces -o wide
kubectl get statefulsets --all-namespaces -o wide
```

Review PDBs:
```bash
kubectl get pdb --all-namespaces
```

## Phase 1: upgrade control plane
Check available versions:
```bash
gcloud container get-server-config --zone=us-central1-c | grep -A10 "channel: STABLE"
```

example output:
```
Fetching server config for us-central1-c
- channel: STABLE
  defaultVersion: 1.35.6-gke.1250000
  upgradeTargetVersion: 1.35.6-gke.1250000
  validVersions:
  - 1.35.6-gke.1250000
  - 1.34.10-gke.1328000
  - 1.34.9-gke.1655001
defaultClusterVersion: 1.35.8-gke.1225000
defaultImageType: COS_CONTAINERD
validImageTypes:
- COS_CONTAINERD
```

Upgrade control plane:
```bash
gcloud container clusters upgrade lab \
    --zone=us-central1-c \
    --master \
    --cluster-version=1.35.6-gke.1250000
```

sample output:
```
Master of cluster [lab] will be upgraded from version [1.34.10-gke.1328000] to 
version [1.35.6-gke.1250000]. This operation is long-running and will block 
other operations on the cluster (except other node pool upgrades) until it has 
run to completion.

Do you want to continue (Y/n)?  y

Upgrading lab...done.                                                          
Updated [https://container.googleapis.com/v1/projects/playground-s-11-ff9fdafb/zones/us-central1-c/clusters/lab].
```

## Phase 2: upgrade node pool

Worker nodes are still not upgraded:
```bash
kubectl get nodes

NAME                                 STATUS   ROLES    AGE   VERSION                INTERNAL-IP   EXTERNAL-IP      OS-IMAGE                             KERNEL-VERSION   CONTAINER-RUNTIME
gke-lab-default-pool-1bf38c92-30x4   Ready    <none>   19m   v1.34.10-gke.1328000   10.128.0.7    34.69.236.91     Container-Optimized OS from Google   6.12.94+         containerd://2.2.7
gke-lab-default-pool-1bf38c92-44d0   Ready    <none>   19m   v1.34.10-gke.1328000   10.128.0.8    34.59.29.59      Container-Optimized OS from Google   6.12.94+         containerd://2.2.7
gke-lab-default-pool-1bf38c92-60w8   Ready    <none>   19m   v1.34.10-gke.1328000   10.128.0.9    136.111.134.51   Container-Optimized OS from Google   6.12.94+         containerd://2.2.7
```

Configure surge settings before upgrade:
```bash


gcloud container node-pools update $NODE_POOL_NAME \
    --cluster=$CLUSTER_NAME \
    --zone=$ZONE \
    --max-surge-upgrade=0 \
    --max-unavailable-upgrade=1
```

Upgrade node pool:
```bash
gcloud container clusters upgrade $CLUSTER_NAME \
  --node-pool=$NODE_POOL_NAME \
  --location=$CONTROL_PLANE_LOCATION \
  --cluster-version=$VERSION
```

sample output:
```
All nodes in node pool [default-pool] of cluster [lab] will be upgraded from 
version [1.34.10-gke.1328000] to version [1.35.6-gke.1250000]. This operation is
 long-running and will block other operations on the cluster (except other node 
pool upgrades) until it has run to completion.

Do you want to continue (Y/n)?  y

Upgrading lab... Updating default-pool, done with 0 out of 3 nodes (0.0%): 1 be
ing processed...⠏                                                              
Upgrading lab... Updating default-pool, done with 1 out of 3 nodes (33.3%): 1 b
eing processed, 1 succeeded...⠼                                                
Upgrading lab... Updating default-pool, done with 2 out of 3 nodes (66.7%): 1 b
eing processed, 2 succeeded...⠹                                                
Upgrading lab... Updating default-pool, done with 3 out of 3 nodes (100.0%): 3 
succeeded...done.                                                              
Updated [https://container.googleapis.com/v1/projects/playground-s-11-ff9fdafb/zones/us-central1-c/clusters/lab].
```

## In a new terminal monitor the upgrade progress.

Check node status:
```bash
kubectl get nodes -w
```

sample output:
```
NAME                                 STATUS                     ROLES    AGE   VERSION
gke-lab-default-pool-1bf38c92-30x4   Ready,SchedulingDisabled   <none>   23m   v1.34.10-gke.1328000
gke-lab-default-pool-1bf38c92-44d0   Ready                      <none>   23m   v1.34.10-gke.1328000
gke-lab-default-pool-1bf38c92-60w8   Ready                      <none>   23m   v1.34.10-gke.1328000
gke-lab-default-pool-1bf38c92-30x4   Ready,SchedulingDisabled   <none>   23m   v1.34.10-gke.1328000
gke-lab-default-pool-1bf38c92-60w8   Ready                      <none>   23m   v1.34.10-gke.1328000
gke-lab-default-pool-1bf38c92-30x4   NotReady,SchedulingDisabled   <none>   23m   v1.34.10-gke.1328000
gke-lab-default-pool-1bf38c92-30x4   NotReady,SchedulingDisabled   <none>   23m   v1.34.10-gke.1328000
gke-lab-default-pool-1bf38c92-30x4   NotReady,SchedulingDisabled   <none>   23m   v1.34.10-gke.1328000
gke-lab-default-pool-1bf38c92-30x4   NotReady,SchedulingDisabled   <none>   24m   v1.34.10-gke.1328000
gke-lab-default-pool-1bf38c92-30x4   NotReady,SchedulingDisabled   <none>   25m   v1.34.10-gke.1328000
gke-lab-default-pool-1bf38c92-60w8   Ready                         <none>   25m   v1.34.10-gke.1328000
gke-lab-default-pool-1bf38c92-30x4   NotReady                      <none>   0s    v1.35.6-gke.1250000
gke-lab-default-pool-1bf38c92-30x4   NotReady                      <none>   0s    v1.35.6-gke.1250000
gke-lab-default-pool-1bf38c92-30x4   NotReady                      <none>   1s    v1.35.6-gke.1250000
gke-lab-default-pool-1bf38c92-30x4   NotReady                      <none>   1s    v1.35.6-gke.1250000
gke-lab-default-pool-1bf38c92-30x4   NotReady                      <none>   1s    v1.35.6-gke.1250000
gke-lab-default-pool-1bf38c92-44d0   Ready                         <none>   25m   v1.34.10-gke.1328000
gke-lab-default-pool-1bf38c92-30x4   NotReady                      <none>   1s    v1.35.6-gke.1250000
gke-lab-default-pool-1bf38c92-30x4   NotReady                      <none>   2s    v1.35.6-gke.1250000
gke-lab-default-pool-1bf38c92-30x4   NotReady                      <none>   2s    v1.35.6-gke.1250000
gke-lab-default-pool-1bf38c92-30x4   NotReady                      <none>   2s    v1.35.6-gke.1250000
gke-lab-default-pool-1bf38c92-30x4   NotReady                      <none>   4s    v1.35.6-gke.1250000
gke-lab-default-pool-1bf38c92-30x4   NotReady                      <none>   4s    v1.35.6-gke.1250000
gke-lab-default-pool-1bf38c92-30x4   Ready                         <none>   5s    v1.35.6-gke.1250000
gke-lab-default-pool-1bf38c92-30x4   Ready                         <none>   5s    v1.35.6-gke.1250000
gke-lab-default-pool-1bf38c92-30x4   Ready                         <none>   9s    v1.35.6-gke.1250000
gke-lab-default-pool-1bf38c92-44d0   Ready                         <none>   25m   v1.34.10-gke.1328000
gke-lab-default-pool-1bf38c92-44d0   Ready,SchedulingDisabled      <none>   25m   v1.34.10-gke.1328000
gke-lab-default-pool-1bf38c92-44d0   Ready,SchedulingDisabled      <none>   25m   v1.34.10-gke.1328000
gke-lab-default-pool-1bf38c92-44d0   Ready,SchedulingDisabled      <none>   25m   v1.34.10-gke.1328000
gke-lab-default-pool-1bf38c92-30x4   Ready                         <none>   31s   v1.35.6-gke.1250000
gke-lab-default-pool-1bf38c92-30x4   Ready                         <none>   31s   v1.35.6-gke.1250000
gke-lab-default-pool-1bf38c92-30x4   Ready                         <none>   41s   v1.35.6-gke.1250000
gke-lab-default-pool-1bf38c92-30x4   Ready                         <none>   44s   v1.35.6-gke.1250000
gke-lab-default-pool-1bf38c92-44d0   Ready,SchedulingDisabled      <none>   26m   v1.34.10-gke.1328000
gke-lab-default-pool-1bf38c92-30x4   Ready                         <none>   61s   v1.35.6-gke.1250000
gke-lab-default-pool-1bf38c92-44d0   Ready,SchedulingDisabled      <none>   26m   v1.34.10-gke.1328000
gke-lab-default-pool-1bf38c92-30x4   Ready                         <none>   92s   v1.35.6-gke.1250000
```

Monitor pod scheduling
```bash
kubectl get pods -w --all-namespaces --field-selector=status.phase=Pending
```

Watch for node cordoning/draining events
```bash
kubectl get events -w --sort-by=.metadata.creationTimestamp
```

## Validation

Verify all pods are running:
```bash
kubectl get pods --all-namespaces | grep -Ev "Running|Completed"
```

Check node readiness
```bash
kubectl get nodes | grep -v Ready
```

Validate cluster components
```bash
kubectl get componentstatuses
```

Monitor upgrade operations from google logs
```bash
gcloud container operations list --filter="TYPE:UPGRADE_CLUSTER"
```

Get detailed operation status
```bash
gcloud container operations describe OPERATION_ID --zone=$ZONE
```
