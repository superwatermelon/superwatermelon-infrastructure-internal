SHELL = /bin/sh

TFPLAN_PATH = terraform.tfplan

TERRAFORM = terraform

TERRAFORM_DIR = terraform

.PHONY: default
default: load plan

.PHONY: check
check:
ifndef JENKINS_KEY_PAIR
	$(error JENKINS_KEY_PAIR is undefined)
endif

ifndef GIT_KEY_PAIR
	$(error GIT_KEY_PAIR is undefined)
endif

ifndef DOCKER_REGISTRY_KEY_PAIR
	$(error DOCKER_REGISTRY_KEY_PAIR is undefined)
endif

.PHONY: load
load:
	$(TERRAFORM) init \
		-no-color \
		-backend=true \
		-backend-config=backend.tfvars \
		-input=false \
		$(TERRAFORM_DIR)

.PHONY: plan
plan: check
	$(TERRAFORM) plan \
		-no-color \
		-out $(TFPLAN_PATH) \
		-var jenkins_key_pair=$(JENKINS_KEY_PAIR) \
		-var git_key_pair=$(GIT_KEY_PAIR) \
		-var docker_registry_key_pair=$(DOCKER_REGISTRY_KEY_PAIR) \
		$(TERRAFORM_DIR)

.PHONY: keys
keys: check
	KEY_PAIR=$(JENKINS_KEY_PAIR) scripts/init-key
	KEY_PAIR=$(GIT_KEY_PAIR) scripts/init-key
	KEY_PAIR=$(DOCKER_REGISTRY_KEY_PAIR) scripts/init-key

.PHONY: apply
apply: keys
	$(TERRAFORM) apply \
		-no-color \
		$(TFPLAN_PATH)

.PHONY: destroy
destroy: check
	$(TERRAFORM) destroy \
		-no-color \
		-var jenkins_key_pair=$(JENKINS_KEY_PAIR) \
		-var git_key_pair=$(GIT_KEY_PAIR) \
		-var docker_registry_key_pair=$(DOCKER_REGISTRY_KEY_PAIR) \
		$(TERRAFORM_DIR)
