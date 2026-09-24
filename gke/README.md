# GKE

## Time to deploy GKE cluster
| cluster type | provisioning tool | time |
| --- | --- | --- |
| gke zonal cluster 1 control plane, 3 worker nodes | gcloud cli | ~10m |
| gke zonal cluster 1 control plane, 3 worker nodes | terraform | >1h |

# gcloud cli

## zonal cluster 1 control plane, 3 worker nodes in a single zone
```bash
gcloud auth login

gcloud config set project $(jq -r ".project_id" credentials.json)

# Enable container service on gcp
gcloud services enable container

# Create a **zonal** kubernetes cluster "lab" with 3 worker nodes
# zonal -> 1 control-plane node
gcloud container clusters create lab \
  --cluster-version 1.34.10-gke.1328000 \
  --num-nodes 3 \
  --machine-type e2-standard-2 \
  --region us-central1-c \
  --enable-secret-manager \
  --workload-pool="$(gcloud config get-value project).svc.id.goog"

gcloud container clusters get-credentials lab --location=us-central1-c
```

# terraform

Follow general instructions on the root [README.md](../README.md)