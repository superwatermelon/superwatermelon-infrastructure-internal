SHELL = /bin/sh

JENKINS_FORMAT_VOLUME = false

GIT_FORMAT_VOLUME = false

TFPLAN_PATH = terraform.tfplan

TERRAFORM = terraform

TERRAFORM_DIR = terraform

TERRAFORM_INIT_OPTS = \
	-no-color \
	-backend=true \
	-input=false \
	-backend-config bucket=$(INTERNAL_TFSTATE_BUCKET) \
	-backend-config region=$(AWS_DEFAULT_REGION)

TERRAFORM_OPTS = \
	-no-color \
	-var jenkins_key_pair=$(JENKINS_KEY_PAIR) \
	-var jenkins_format_volume=$(JENKINS_FORMAT_VOLUME) \
	-var git_key_pair=$(GIT_KEY_PAIR) \
	-var git_format_volume=$(GIT_FORMAT_VOLUME) \
	-var test_iam_role=$(TEST_IAM_ROLE) \
	-var stage_iam_role=$(STAGE_IAM_ROLE) \
	-var live_iam_role=$(LIVE_IAM_ROLE) \
	-var internal_tfstate_bucket=$(INTERNAL_TFSTATE_BUCKET) \
	-var test_tfstate_bucket=$(TEST_TFSTATE_BUCKET) \
	-var stage_tfstate_bucket=$(STAGE_TFSTATE_BUCKET) \
	-var live_tfstate_bucket=$(LIVE_TFSTATE_BUCKET) \
	-var internal_hosted_zone=$(INTERNAL_HOSTED_ZONE) \
	-var test_hosted_zone=$(TEST_HOSTED_ZONE) \
	-var stage_hosted_zone=$(STAGE_HOSTED_ZONE) \
	-var live_hosted_zone=$(LIVE_HOSTED_ZONE)

.PHONY: default
default: load plan

.PHONY: check
check:
ifndef AWS_DEFAULT_REGION
	$(error AWS_DEFAULT_REGION is undefined)
endif

ifndef JENKINS_KEY_PAIR
	$(error JENKINS_KEY_PAIR is undefined)
endif

ifndef GIT_KEY_PAIR
	$(error GIT_KEY_PAIR is undefined)
endif

ifndef TEST_IAM_ROLE
	$(error TEST_IAM_ROLE is undefined)
endif

ifndef STAGE_IAM_ROLE
	$(error STAGE_IAM_ROLE is undefined)
endif

ifndef LIVE_IAM_ROLE
	$(error LIVE_IAM_ROLE is undefined)
endif

ifndef INTERNAL_TFSTATE_BUCKET
	$(error INTERNAL_TFSTATE_BUCKET is undefined)
endif

ifndef TEST_TFSTATE_BUCKET
	$(error TEST_TFSTATE_BUCKET is undefined)
endif

ifndef STAGE_TFSTATE_BUCKET
	$(error STAGE_TFSTATE_BUCKET is undefined)
endif

ifndef LIVE_TFSTATE_BUCKET
	$(error LIVE_TFSTATE_BUCKET is undefined)
endif

ifndef INTERNAL_HOSTED_ZONE
	$(error INTERNAL_HOSTED_ZONE is undefined)
endif

ifndef TEST_HOSTED_ZONE
	$(error TEST_HOSTED_ZONE is undefined)
endif

ifndef STAGE_HOSTED_ZONE
	$(error STAGE_HOSTED_ZONE is undefined)
endif

ifndef LIVE_HOSTED_ZONE
	$(error LIVE_HOSTED_ZONE is undefined)
endif

.PHONY: load
load: check
	$(TERRAFORM) init $(TERRAFORM_INIT_OPTS) $(TERRAFORM_DIR)

.PHONY: keys
keys: check
	KEY_PAIR=$(JENKINS_KEY_PAIR) scripts/init-key
	KEY_PAIR=$(GIT_KEY_PAIR) scripts/init-key

.PHONY: plan
plan: check
	$(TERRAFORM) plan $(TERRAFORM_OPTS) -out $(TFPLAN_PATH) $(TERRAFORM_DIR)


.PHONY: apply
apply: keys
	$(TERRAFORM) apply -no-color $(TFPLAN_PATH)

.PHONY: destroy
destroy: check
	$(TERRAFORM) destroy $(TERRAFORM_OPTS) $(TERRAFORM_DIR)
