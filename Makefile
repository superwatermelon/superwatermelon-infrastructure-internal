DIR := ./terraform

TFPLAN_PATH ?= terraform.tfplan
TFSTATE_PATH ?= terraform.tfstate

JENKINS_FORMAT_VOLUME ?= false
GIT_FORMAT_VOLUME ?= false

INITKEYSSCRIPT := scripts/init-keys
TFCONFIG := terraform/git.tf terraform/jenkins.tf terraform/main.tf
JENKINSINITSCRIPTS := \
    jenkins/init.groovy.d/aws.groovy \
    jenkins/init.groovy.d/git.groovy \
    jenkins/init.groovy.d/master.groovy \
    jenkins/init.groovy.d/security.groovy

TERRAFORM_VARS := -no-color \
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
	-var live_tfstate_bucket=$(LIVE_TFSTATE_BUCKET)

default: load plan

check:
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

load:
	terraform get $(DIR)

refresh:
	terraform refresh $(TERRAFORM_VARS) $(DIR)

keys: $(INITKEYSSCRIPT)
	$(INITKEYSSCRIPT) \
		--jenkins-key-pair=$(JENKINS_KEY_PAIR) \
		--git-key-pair=$(GIT_KEY_PAIR)

apply: keys $(TFPLAN_PATH)
	terraform apply \
		-state-out $(TFSTATE_PATH) \
		-no-color $(TFPLAN_PATH)

destroy: check
	terraform destroy \
		$(TERRAFORM_VARS) \
		-state $(TFSTATE_PATH) \
		$(DIR)

plan: check $(TFCONFIG) $(JENKINSINITSCRIPTS)
	terraform plan \
		$(TERRAFORM_VARS) \
		-out $(TFPLAN_PATH) \
		-state $(TFSTATE_PATH) \
		$(DIR)

.PHONY: default check load refresh plan keys apply destroy
