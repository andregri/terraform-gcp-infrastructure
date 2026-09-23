# GKE

## Create a zonal GKE cluster (1 control plane - 3 worker nodes)

Create a zonal cluster with secret plugin enabled:
```bash
gcloud auth login

gcloud config set project $(jq -r ".project_id" credentials.json)

# Enable container service on gcp
gcloud services enable container

# Create a **zonal** kubernetes cluster "lab" with 3 worker nodes
# zonal -> 1 control-plane node
gcloud container clusters create lab \
  --cluster-version 1.35.6-gke.1250000 \
  --num-nodes 3 \
  --machine-type e2-standard-2 \
  --region us-central1-c \
  --enable-secret-manager \
  --workload-pool="$(gcloud config get-value project).svc.id.goog"

gcloud container clusters get-credentials lab --location=us-central1-c
```

## Create a secret on GCP Secret Manager

Create a secret named "test" using web console.

Create the service account:
```bash
gcloud beta services identity create --service "secretmanager.googleapis.com"
```

The command should output the service account email:
```
Service identity created: service-396376061547@gcp-sa-secretmanager.iam.gserviceaccount.com
```

Bind the role "roles/pubsub.publisher" between the topic and the service account:
```bash
export PROJECT=$(gcloud config get-value project)
gcloud pubsub topics add-iam-policy-binding projects/${PROJECT}/topics/secret-topic \
    --member "serviceAccount:service-396376061547@gcp-sa-secretmanager.iam.gserviceaccount.com" \
    --role "roles/pubsub.publisher"
```

Expected output is:
```
Updated IAM policy for topic [secret-topic].
bindings:
- members:
  - serviceAccount:service-396376061547@gcp-sa-secretmanager.iam.gserviceaccount.com
  role: roles/pubsub.publisher
etag: BwZcIkQpf7k=
version: 1
```

## Verify the CSI secret store provider is running

Monitor the pods are running:
```bash
kubectl --namespace=kube-system get pods -l "app=csi-secrets-store-gke"
kubectl --namespace=kube-system get pods -l "app=csi-secrets-store-provider-gke"
```

Output should be:
```
NAME                                   READY   STATUS    RESTARTS   AGE
csi-secrets-store-provider-gke-g52m5   1/1     Running   0          26m
csi-secrets-store-provider-gke-lg4rw   1/1     Running   0          26m
csi-secrets-store-provider-gke-zdblh   1/1     Running   0          26m

NAME                          READY   STATUS    RESTARTS   AGE
csi-secrets-store-gke-2hz7z   3/3     Running   0          26m
csi-secrets-store-gke-cdk5t   3/3     Running   0          26m
csi-secrets-store-gke-j67j9   3/3     Running   0          26m
```

## Create a service account with secret access role

Create a service account:
```bash
export KSA_NAME="mypodserviceaccount"

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: $KSA_NAME
  namespace: default
EOF
```

Bind the role "roles/secretmanager.secretAccessor" to the service account:
```bash
export PROJECT_NUMBER=$(gcloud projects list --filter PROJECT_ID=$PROJECT --format="value(PROJECT_NUMBER)")
export SECRET_NAME="test"
export SECRET_VERSION="latest"

gcloud secrets add-iam-policy-binding $SECRET_NAME \
    --role=roles/secretmanager.secretAccessor \
    --member=principal://iam.googleapis.com/projects/$PROJECT_NUMBER/locations/global/workloadIdentityPools/$PROJECT.svc.id.goog/subject/ns/default/sa/mypodserviceaccount
```

Expected output:
```
Updated IAM policy for secret [test].
bindings:
- members:
  - principal://iam.googleapis.com/projects/396376061547/locations/global/workloadIdentityPools/playground-s-11-622305b3.svc.id.goog/subject/ns/default/sa/mypodserviceaccount
  role: roles/secretmanager.secretAccessor
etag: BwZcIpxCPIo=
version: 1
```

Create the SecretProviderClass:
```bash
export SECRET_PROVIDER_CLASS_NAME="app-secrets"

cat <<EOF | kubectl apply -f -
apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: $SECRET_PROVIDER_CLASS_NAME
spec:
  provider: gke
  parameters:
    secrets: |
      - resourceName: "projects/$PROJECT/secrets/$SECRET_NAME/versions/$SECRET_VERSION"
        path: "secret.txt"
EOF
```

Get the SecretProviderClass:
```bash
kubectl get SecretProviderClasses
```

## Mount the volume on the pod
```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: mypod
  namespace: default
spec:
  serviceAccountName: $KSA_NAME
  containers:
  - image: gcr.io/google.com/cloudsdktool/cloud-sdk:slim
    imagePullPolicy: IfNotPresent
    name: mypod
    resources:
      requests:
        cpu: 100m
    stdin: true
    stdinOnce: true
    terminationMessagePath: /dev/termination-log
    terminationMessagePolicy: File
    tty: true
    volumeMounts:
      - mountPath: "/var/secrets"
        name: mysecret
  volumes:
  - name: mysecret
    csi:
      driver: secrets-store-gke.csi.k8s.io
      readOnly: true
      volumeAttributes:
        secretProviderClass: $SECRET_PROVIDER_CLASS_NAME
EOF
```

Monitor the po:
```bash
kubectl describe po mypod
```

Read the secret from inside the pod:
```bash
kubectl exec -it mypod -- cat /var/secrets/secret.txt
```