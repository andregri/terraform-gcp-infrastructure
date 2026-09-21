# terraform-gcp-infrastructure

Login to GCP:
```bash

```

## Project hardening
Remove the **default-allow-ssh** firewall rule:
```bash
gcloud auth login
export TF_VAR_project_id=$(jq -r ".project_id" credentials.json)

gcloud compute firewall-rules delete default-allow-ssh --project ${TF_VAR_project_id}
```

Expected output is similar to:
```
The following firewalls will be deleted:
 - [default-allow-ssh]

Do you want to continue (Y/n)?  y

Deleted [https://www.googleapis.com/compute/v1/projects/playground-s-11-657640ae/global/firewalls/default-allow-ssh].
```

## Bootstrap a bucket for terraform state
The bootstrap configuration creates:
- creates a bucket for terraform state
- creates a firewall policy to allow ssh traffic from IAP ips (35.235.240.0/20)
- add role **IAP-secured Tunnel User** to acloudguru user

```bash
export TF_VAR_project_id=$(jq -r ".project_id" credentials.json)
export TF_VAR_grant_iap_secured_tunnel_users_email=""
#export GOOGLE_APPLICATION_CREDENTIALS="../credentials.json"
gcloud auth application-default login

make tf-cleanup FOLDER=bootstrap
make tf-init FOLDER=bootstrap
# or if you need to upgrade drivers: make tf-init FOLDER=bootstrap TF_FLAGS="-upgrade"
make tf-apply FOLDER=bootstrap
```

## Deploy infrastructure
```bash
export FOLDER="single-vm"
make tf-cleanup FOLDER=$FOLDER
make tf-init FOLDER=$FOLDER
# or if you need to upgrade drivers: make tf-init FOLDER=$FOLDER TF_FLAGS="-upgrade"
make tf-apply FOLDER=$FOLDER
```