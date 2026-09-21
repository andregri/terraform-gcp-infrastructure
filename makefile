.PHONY: tf-cleanup
tf-cleanup:
	@echo "Removing .terraform folder and tfstate in $(FOLDER)/..."
	cd $(FOLDER) && rm -rf .terraform && rm terraform.tfstate*

# USAGE: e.g. make tf-init FOLDER=bootstrap TF_FLAGS="-upgrade"
.PHONY: tf-init
tf-init:
	@echo "Initializing Terraform backend of $(FOLDER)..."
	cd $(FOLDER) && terraform init $(TF_FLAGS)

.PHONY: tf-apply
tf-apply:
	@echo "Apply terraform configuration in $(FOLDER)/..."
	cd $(FOLDER) && terraform apply -auto-approve
