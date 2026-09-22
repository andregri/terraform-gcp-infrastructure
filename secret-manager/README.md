# Google Secret and kind cluster

## 1. Create the secret on gcp

Create the secret:

Create the service account:
```bash
gcloud beta services identity create --service "secretmanager.googleapis.com"
```

The command should output the service account email:
```
Service identity created: service-22934348577@gcp-sa-secretmanager.iam.gserviceaccount.com
```

Bind the role "roles/pubsub.publisher" between the topic and the service account:
```bash
gcloud pubsub topics add-iam-policy-binding projects/playground-s-11-3438fb1f/topics/secret-topic \                         
    --member "serviceAccount:service-22934348577@gcp-sa-secretmanager.iam.gserviceaccount.com" \ 
    --role "roles/pubsub.publisher"
```

Expected output is:
```
Updated IAM policy for topic [secret-topic].
bindings:
- members:
  - serviceAccount:service-22934348577@gcp-sa-secretmanager.iam.gserviceaccount.com
  role: roles/pubsub.publisher
etag: BwZcD4wqdmE=
version: 1
```

## 2. Prepare the kind cluster

Create the cluster
```bash
kind create cluster --name gcp-secret-test

kubectl get nodes
```

output:
```
NAME                            STATUS   ROLES           AGE   VERSION
gcp-secret-test-control-plane   Ready    control-plane   63s   v1.37.0
```

Install the secret store csi driver:
```bash
helm repo add secrets-store-csi-driver https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts

helm repo update

helm install csi-secrets-store \
  secrets-store-csi-driver/secrets-store-csi-driver \
  -n kube-system
```

Monitor the pods are running
```bash
kubectl --namespace=kube-system get pods -l "app=secrets-store-csi-driver"
```

output should be:
```
NAME                                               READY   STATUS    RESTARTS   AGE
csi-secrets-store-secrets-store-csi-driver-pgljp   3/3     Running   0          7s
```

Install the gcp provider for the secret store csi driver:
```bash
kubectl apply -f https://raw.githubusercontent.com/GoogleCloudPlatform/secrets-store-csi-driver-provider-gcp/refs/heads/main/deploy/provider-gcp-plugin.yaml
```

Monitor the pods:
```bash
kubectl --namespace=kube-system get pods -l "app=csi-secrets-store-provider-gcp"
```

output should be:
```
NAME                                   READY   STATUS    RESTARTS   AGE
csi-secrets-store-provider-gcp-gwmzd   1/1     Running   0          2m2s
```

## 3. Create a service account with secret access role
Create a service account:
```bash
export SERVICE_ACCOUNT_NAME="kind-secret-reader"
export PROJECT=$(gcloud config get-value project)
gcloud iam service-accounts create ${SERVICE_ACCOUNT_NAME} \
  --project=${PROJECT}
```

Bind the role "roles/secretmanager.secretAccessor" to the service account:
```bash
export SECRET_NAME="test"
gcloud secrets add-iam-policy-binding "${SECRET_NAME}" \
  --project=${PROJECT} \
  --member="serviceAccount:kind-secret-reader@${PROJECT}.iam.gserviceaccount.com" \
  --role="roles/secretmanager.secretAccessor"
```

Create a json key:
```bash
gcloud iam service-accounts keys create gcp-${SERVICE_ACCOUNT_NAME}-sa.json \
  --iam-account=${SERVICE_ACCOUNT_NAME}@${PROJECT}.iam.gserviceaccount.com
```

Create a secret on kubernetes with credentials:
```bash
kubectl create secret generic gcp-credentials \
  -n kube-system \
  --from-file=credentials.json=./gcp-${SERVICE_ACCOUNT_NAME}-sa.json
```

Edit the gcp provider daemonset:
```bash
kubectl -n kube-system edit ds/csi-secrets-store-provider-gcp
```

Add the following snippets:
```bash
env:
  - name: GOOGLE_APPLICATION_CREDENTIALS
    value: /var/secrets/google/credentials.json
...
volumeMounts:
  - name: gcp-credentials
    mountPath: /var/secrets/google
    readOnly: true
...
volumes:
  - name: gcp-credentials
    secret:
      secretName: gcp-credentials
```