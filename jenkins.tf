#
# A Jenkins server.
#
# It is backed by a general purpose EBS volume, 10 GB by default,
# configurable via the jenkins_volume_size variable.
#

variable "jenkins_key_pair" {
  description = "The name of the key pair to use"
}

variable "jenkins_instance_type" {
  description = "The AWS instance type to use for the instance"
  default     = "t2.small"
}

variable "jenkins_volume_device" {
  description = "The device name of the block storage volume"
  default     = "xvdf"
}

variable "jenkins_volume_size" {
  description = "The size of the volume in GB"
  default     = 10
}

variable "jenkins_agent_name" {
  description = "The name of the Jenkins agent"
  default     = "jenkins-agent"
}

variable "jenkins_cloud_name" {
  description = "The name of the cloud to use for Jenkins agents"
  default     = "aws"
}

variable "internal_hosted_zone" {
  description = "The private hosted zone for the internal VPC"
}

variable "test_hosted_zone" {
  description = "The private hosted zone for the test VPC"
}

variable "stage_hosted_zone" {
  description = "The private hosted zone for the stage VPC"
}

variable "live_hosted_zone" {
  description = "The private hosted zone for the live VPC"
}

variable "jenkins_url" {
  description = "The URL for the Jenkins UI"
}

variable "jenkins_admin_address" {
  description = "The support / admin contact email address"
}

variable "jenkins_agent_key_pair_prefix" {
  description = "The prefix to use for keys created by Jenkins for agents"
  default = "jenkins-agent"
}

variable "jenkins_agent_region" {
  description = "The region into which to deploy Jenkins agents"
  default     = "eu-west-1"
}

data "aws_region" "current" {}

data "template_file" "jenkins_environment" {
  template = <<EOF
INTERNAL_IAM_ROLE=${data.terraform_remote_state.seed.internal_deployment_role_arn}
TEST_IAM_ROLE=${data.terraform_remote_state.seed.test_deployment_role_arn}
STAGE_IAM_ROLE=${data.terraform_remote_state.seed.stage_deployment_role_arn}
LIVE_IAM_ROLE=${data.terraform_remote_state.seed.live_deployment_role_arn}
SEED_TFSTATE_BUCKET=${var.seed_tfstate_bucket}
INTERNAL_TFSTATE_BUCKET=${data.terraform_remote_state.seed.internal_tfstate_bucket}
TEST_TFSTATE_BUCKET=${data.terraform_remote_state.seed.test_tfstate_bucket}
STAGE_TFSTATE_BUCKET=${data.terraform_remote_state.seed.stage_tfstate_bucket}
LIVE_TFSTATE_BUCKET=${data.terraform_remote_state.seed.live_tfstate_bucket}
INTERNAL_HOSTED_ZONE=${var.internal_hosted_zone}
TEST_HOSTED_ZONE=${var.test_hosted_zone}
STAGE_HOSTED_ZONE=${var.stage_hosted_zone}
LIVE_HOSTED_ZONE=${var.live_hosted_zone}
JENKINS_URL=${var.jenkins_url}
JENKINS_ADMIN_ADDRESS=${var.jenkins_admin_address}
JENKINS_AGENT_KEY_PAIR_PREFIX=${var.jenkins_agent_key_pair_prefix}
JENKINS_AGENT_AMI=${data.aws_ami.amazon_linux.id}
JENKINS_AGENT_REGION=${var.jenkins_agent_region}
JENKINS_AGENT_SUBNET_ID=${aws_subnet.subnet.2.id}
JENKINS_AGENT_INSTANCE_PROFILE=${module.jenkins_agent.profile_arn}
JENKINS_AGENT_SECURITY_GROUPS=${aws_security_group.jenkins_agent_sg.id}
JENKINS_AGENT_NAME=${var.jenkins_agent_name}
JENKINS_CLOUD_NAME=${var.jenkins_cloud_name}
JENKINS_SCRIPT_SECURITY=off
AWS_REGION=${data.aws_region.current.name}
EOF
}

module "jenkins" {
  source            = "modules/jenkins"
  name              = "jenkins-master"
  environment       = "${data.template_file.jenkins_environment.rendered}"
  key_name          = "${var.jenkins_key_pair}"
  availability_zone = "${aws_subnet.subnet.0.availability_zone}"
  subnet_id         = "${aws_subnet.subnet.0.id}"

  vpc_security_group_ids = [
    "${aws_security_group.jenkins_sg.id}"
  ]

  jenkins_agent_role_arn = "${module.jenkins_agent.role_arn}"
}

module "jenkins_agent" {
  source                       = "modules/jenkins-agent"
  name                         = "jenkins-agent"
  internal_deployment_role_arn = "${data.terraform_remote_state.seed.internal_deployment_role_arn}"
  internal_ecr_role_arn        = "${data.terraform_remote_state.seed.internal_ecr_role_arn}"
  test_deployment_role_arn     = "${data.terraform_remote_state.seed.test_deployment_role_arn}"
  test_ecr_role_arn            = "${data.terraform_remote_state.seed.test_ecr_role_arn}"
  stage_deployment_role_arn    = "${data.terraform_remote_state.seed.stage_deployment_role_arn}"
  stage_ecr_role_arn           = "${data.terraform_remote_state.seed.stage_ecr_role_arn}"
  live_deployment_role_arn     = "${data.terraform_remote_state.seed.live_deployment_role_arn}"
  live_ecr_role_arn            = "${data.terraform_remote_state.seed.live_ecr_role_arn}"
}
