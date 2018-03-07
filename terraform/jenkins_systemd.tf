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

variable "jenkins_agent_region" {
  description = "The region into which to deploy Jenkins agents"
  default     = "eu-west-1"
}

variable "jenkins_url" {
  description = "The URL for the Jenkins UI"
}

variable "jenkins_cloud_name" {
  description = "The name of the cloud to use for Jenkins agents"
  default     = "aws"
}

variable "jenkins_admin_address" {
  description = "The support / admin contact email address"
}

variable "jenkins_agent_key_pair_prefix" {
  description = "The prefix to use for keys created by Jenkins for agents"
  default     = "jenkins-agent"
}

/*
 * The format-volume.service conditionally formats and partitions the
 * attached EBS volume, that is, if the EBS volume is already formatted
 * the service will not attempt to format it again. This is so that data
 * from a previous instance can be reattached to a new instance say, for
 * example, we needed to upgrade the AMI or change the instance type we
 * can edit this configuration and apply the changes while retaining the
 * persistent state, i.e. workspaces, plugins, users and logs for Jenkins.
 * The home-jenkins.mount unit mounts the EBS volume at /home/jenkins and
 * the home-jenkins.service changes permissions so that the jenkins user
 * has full permissions to this mount point.
 * The jenkins.service runs the Jenkins Docker container.
 * TODO: Discover the most resilient approach to handling restarting,
 * i.e. at the Docker level or at the systemd level.
 * The jenkins user is used to mirror the user within the Docker container,
 * hence the 1000 uid.
 */

data "template_file" "jenkins_service_unit" {
 template = <<EOF
[Unit]
Requires=home-jenkins.service docker.service
After=home-jenkins.service docker.service
[Service]
Restart=always
ExecStartPre=/usr/bin/docker pull superwatermelon/jenkins:v0.4.1
ExecStart=/usr/bin/docker run \
  --rm \
  --publish 8080:8080 \
  --volume /home/jenkins:/var/jenkins_home \
  --env INTERNAL_IAM_ROLE=$${internal_iam_role} \
  --env TEST_IAM_ROLE=$${test_iam_role} \
  --env STAGE_IAM_ROLE=$${stage_iam_role} \
  --env LIVE_IAM_ROLE=$${live_iam_role} \
  --env SEED_TFSTATE_BUCKET=$${seed_tfstate_bucket} \
  --env INTERNAL_TFSTATE_BUCKET=$${internal_tfstate_bucket} \
  --env TEST_TFSTATE_BUCKET=$${test_tfstate_bucket} \
  --env STAGE_TFSTATE_BUCKET=$${stage_tfstate_bucket} \
  --env LIVE_TFSTATE_BUCKET=$${live_tfstate_bucket} \
  --env INTERNAL_HOSTED_ZONE=$${internal_hosted_zone} \
  --env TEST_HOSTED_ZONE=$${test_hosted_zone} \
  --env STAGE_HOSTED_ZONE=$${stage_hosted_zone} \
  --env LIVE_HOSTED_ZONE=$${live_hosted_zone} \
  --env JENKINS_URL=$${jenkins_url} \
  --env JENKINS_ADMIN_ADDRESS=$${jenkins_admin_address} \
  --env JENKINS_AGENT_KEY_PAIR_PREFIX=$${jenkins_agent_key_pair_prefix} \
  --env JENKINS_AGENT_AMI=$${jenkins_agent_ami} \
  --env JENKINS_AGENT_REGION=$${jenkins_agent_region} \
  --env JENKINS_AGENT_SUBNET_ID=$${jenkins_agent_subnet_id} \
  --env JENKINS_AGENT_INSTANCE_PROFILE=$${jenkins_agent_instance_profile} \
  --env JENKINS_AGENT_SECURITY_GROUPS=$${jenkins_agent_security_groups} \
  --env JENKINS_AGENT_NAME=$${jenkins_agent_name} \
  --env JENKINS_CLOUD_NAME=$${jenkins_cloud_name} \
  --env JENKINS_SCRIPT_SECURITY=off \
  --env AWS_REGION=$${aws_region} \
  --name jenkins \
  superwatermelon/jenkins:v0.4.4
[Install]
WantedBy=multi-user.target
EOF
  vars = {
    internal_iam_role              = "${data.terraform_remote_state.seed.internal_deployment_role_arn}"
    test_iam_role                  = "${data.terraform_remote_state.seed.test_deployment_role_arn}"
    stage_iam_role                 = "${data.terraform_remote_state.seed.stage_deployment_role_arn}"
    live_iam_role                  = "${data.terraform_remote_state.seed.live_deployment_role_arn}"
    seed_tfstate_bucket            = "${var.seed_tfstate_bucket}"
    internal_tfstate_bucket        = "${data.terraform_remote_state.seed.internal_tfstate_bucket}"
    test_tfstate_bucket            = "${data.terraform_remote_state.seed.test_tfstate_bucket}"
    stage_tfstate_bucket           = "${data.terraform_remote_state.seed.stage_tfstate_bucket}"
    live_tfstate_bucket            = "${data.terraform_remote_state.seed.live_tfstate_bucket}"
    internal_hosted_zone           = "${var.internal_hosted_zone}"
    test_hosted_zone               = "${var.test_hosted_zone}"
    stage_hosted_zone              = "${var.stage_hosted_zone}"
    live_hosted_zone               = "${var.live_hosted_zone}"
    jenkins_url                    = "${var.jenkins_url}"
    jenkins_admin_address          = "${var.jenkins_admin_address}"
    jenkins_agent_key_pair_prefix  = "${var.jenkins_agent_key_pair_prefix}"
    jenkins_agent_ami              = "${data.aws_ami.amazon_linux.id}"
    jenkins_agent_region           = "${data.aws_region.current.name}"
    jenkins_agent_subnet_id        = "${aws_subnet.subnet.2.id}"
    jenkins_agent_instance_profile = "${aws_iam_instance_profile.jenkins_agent_profile.arn}"
    jenkins_agent_security_groups  = "${aws_security_group.jenkins_agent_sg.id}"
    jenkins_agent_name             = "jenkins-agent"
    jenkins_cloud_name             = "${var.jenkins_cloud_name}"
    aws_region                     = "${data.aws_region.current.name}"
  }
}

data "aws_region" "current" {}

data "template_file" "jenkins_home_service_unit" {
  template = <<EOF
[Unit]
Requires=home-jenkins.mount
After=home-jenkins.mount
[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/bin/rsync -rdavh --progress /mnt/jenkins/ /home/jenkins/
ExecStart=/usr/bin/chown -R jenkins:jenkins /home/jenkins
[Install]
WantedBy=multi-user.target
EOF
}

data "template_file" "jenkins_home_mount_unit" {
  template = <<EOF
[Unit]
Requires=dev-$${volume}1.device
After=dev-$${volume}1.device jenkins-format.service
[Mount]
What=/dev/$${volume}1
Where=/home/jenkins
Type=ext4
[Install]
WantedBy=multi-user.target
EOF
  vars = {
    volume = "${var.jenkins_volume_device}"
  }
}

data "template_file" "jenkins_format_service" {
  template = <<EOF
[Unit]
Requires=dev-$${volume}.device
After=dev-$${volume}.device
[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/bin/bash -xc "parted /dev/$${volume} mklabel gpt mkpart primary 0%% 100%% && mkfs.ext4 /dev/$${volume}1"
[Install]
WantedBy=multi-user.target
EOF
  vars = {
    volume = "${var.jenkins_volume_device}"
  }
}
