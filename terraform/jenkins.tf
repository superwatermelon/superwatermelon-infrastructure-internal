/*
 * A Jenkins server.
 *
 * It is backed by a general purpose EBS volume, 20 GB by default,
 * configurable via the jenkins_volume_size variable.
 *
 * The availability_zone, subnet and coreos_ami are
 * required variables. The availability_zone must match the
 * availability zone of the subnet.
 */

variable "test_iam_role" {
  description = "The IAM role that is used by Jenkins to deploy to test"
}

variable "stage_iam_role" {
  description = "The IAM role that is used by Jenkins to deploy to stage"
}

variable "live_iam_role" {
  description = "The IAM role that is used by Jenkins to deploy to live"
}

variable "test_hosted_zone" {
  description = "The private hosted zone for the test VPC."
}

variable "stage_hosted_zone" {
  description = "The private hosted zone for the stage VPC."
}

variable "live_hosted_zone" {
  description = "The private hosted zone for the live VPC."
}

variable "internal_tfstate_bucket" {
  description = "The S3 bucket that should contain the tfstate"
}

variable "test_tfstate_bucket" {
  description = "The S3 bucket that should contain the tfstate for test"
}

variable "stage_tfstate_bucket" {
  description = "The S3 bucket that should contain the tfstate for stage"
}

variable "live_tfstate_bucket" {
  description = "The S3 bucket that should contain the tfstate for live"
}

variable "jenkins_instance_type" {
  description = "The AWS instance type to use for the instance"
  default     = "t2.micro"
}

variable "jenkins_key_pair" {
  description = "The name of the key pair to use"
  default     = "jenkins"
}

variable "jenkins_snapshot_id" {
  description = "The ID of the Jenkins volume snapshot"
  default     = ""
}

variable "jenkins_volume_device" {
  description = "The device name of the block storage volume"
  default     = "xvdf"
}

variable "jenkins_volume_size" {
  description = "The size of the volume in GB"
  default     = 10
}

variable "jenkins_agent_region" {
  description = "The region into which to deploy Jenkins agents"
  default     = "eu-west-1"
}

variable "jenkins_url" {
  description = "The URL for the Jenkins UI"
  default     = "http://jenkins.superwatermelon.org:8080/"
}

variable "jenkins_cloud_name" {
  description = "The name of the cloud to use for Jenkins agents"
  default     = "aws"
}

variable "jenkins_admin_address" {
  description = "The support / admin contact email address"
  default     = "support@superwatermelon.com"
}

variable "jenkins_agent_key_pair_prefix" {
  description = "The prefix to use for keys created by Jenkins for agents"
  default     = "tools-jenkins-agent"
}

variable "jenkins_format_volume" {
  description = "Should the Jenkins volume be formatted (use for first launch)"
  default     = false
}

resource "aws_instance" "jenkins" {
  ami                    = "${data.aws_ami.coreos.id}"
  instance_type          = "${var.jenkins_instance_type}"
  key_name               = "${var.jenkins_key_pair}"
  subnet_id              = "${aws_subnet.subnet.id}"
  iam_instance_profile   = "${aws_iam_instance_profile.jenkins_profile.id}"
  user_data              = "${data.template_file.jenkins_ignition.rendered}"
  vpc_security_group_ids = [
    "${aws_security_group.jenkins_sg.id}",
    "${aws_security_group.users_sg.id}"
  ]

  root_block_device {
    volume_type = "gp2"
  }

  tags {
    Name = "${var.stack_name}-jenkins"
  }
}

data "template_file" "jenkins_ignition" {
  template = <<EOF
{
  "ignition":{"version":"2.0.0"},
  "passwd":{
    "users":[
      {"name":"jenkins","create":{"uid":1000}}
    ]
  },
  "storage":{
    "files":[
      {"filesystem":"root","path":"/mnt/jenkins/init.groovy.d/aws.groovy","contents":{"source":$${init_aws_groovy}},"mode":420,"user":{"id":1000},"group":{"id":1000}},
      {"filesystem":"root","path":"/mnt/jenkins/init.groovy.d/git.groovy","contents":{"source":$${init_git_groovy}},"mode":420,"user":{"id":1000},"group":{"id":1000}},
      {"filesystem":"root","path":"/mnt/jenkins/init.groovy.d/master.groovy","contents":{"source":$${init_master_groovy}},"mode":420,"user":{"id":1000},"group":{"id":1000}},
      {"filesystem":"root","path":"/mnt/jenkins/init.groovy.d/security.groovy","contents":{"source":$${init_security_groovy}},"mode":420,"user":{"id":1000},"group":{"id":1000}}
    ]
  },
  "systemd":{
    "units":[
      {"name":"docker.socket","enable":true},
      {"name":"containerd.service","enable":true},
      {"name":"docker.service","enable":true},
      {"name":"jenkins.service","enable":true,"contents":$${jenkins_service_unit}},
      {"name":"home-jenkins.service","enable":true,"contents":$${jenkins_home_service_unit}},
      {"name":"home-jenkins.mount","enable":true,"contents":$${jenkins_home_mount_unit}},
      {"name":"jenkins-format.service","enable":$${jenkins_format_service_enabled},"contents":$${jenkins_format_service}}
    ]
  }
}
EOF
  vars = {
    jenkins_service_unit           = "${jsonencode(data.template_file.jenkins_service_unit.rendered)}"
    jenkins_home_service_unit      = "${jsonencode(data.template_file.jenkins_home_service_unit.rendered)}"
    jenkins_home_mount_unit        = "${jsonencode(data.template_file.jenkins_home_mount_unit.rendered)}"
    jenkins_format_service         = "${jsonencode(data.template_file.jenkins_format_service.rendered)}"
    jenkins_format_service_enabled = "${var.jenkins_format_volume == true}"

    # Jenkins init scripts
    init_aws_groovy                = "${jsonencode("data:text/plain;base64,${base64encode(file("${path.root}/../jenkins/init.groovy.d/aws.groovy"))}")}"
    init_git_groovy                = "${jsonencode("data:text/plain;base64,${base64encode(file("${path.root}/../jenkins/init.groovy.d/git.groovy"))}")}"
    init_master_groovy             = "${jsonencode("data:text/plain;base64,${base64encode(file("${path.root}/../jenkins/init.groovy.d/master.groovy"))}")}"
    init_security_groovy           = "${jsonencode("data:text/plain;base64,${base64encode(file("${path.root}/../jenkins/init.groovy.d/security.groovy"))}")}"
  }
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
ExecStart=/usr/bin/docker run \
  --rm \
  --publish 8080:8080 \
  --volume /home/jenkins:/var/jenkins_home \
  --env TEST_IAM_ROLE=$${test_iam_role} \
  --env STAGE_IAM_ROLE=$${stage_iam_role} \
  --env LIVE_IAM_ROLE=$${live_iam_role} \
  --env TFSTATE_BUCKET=$${internal_tfstate_bucket} \
  --env TEST_TFSTATE_BUCKET=$${test_tfstate_bucket} \
  --env STAGE_TFSTATE_BUCKET=$${stage_tfstate_bucket} \
  --env LIVE_TFSTATE_BUCKET=$${live_tfstate_bucket} \
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
  --name jenkins superwatermelon/jenkins:v0.3.1
[Install]
WantedBy=multi-user.target
EOF
  vars = {
    test_iam_role                  = "${var.test_iam_role}"
    stage_iam_role                 = "${var.stage_iam_role}"
    live_iam_role                  = "${var.live_iam_role}"
    internal_tfstate_bucket        = "${var.internal_tfstate_bucket}"
    test_tfstate_bucket            = "${var.test_tfstate_bucket}"
    stage_tfstate_bucket           = "${var.stage_tfstate_bucket}"
    live_tfstate_bucket            = "${var.live_tfstate_bucket}"
    test_hosted_zone               = "${var.test_hosted_zone}"
    stage_hosted_zone              = "${var.stage_hosted_zone}"
    live_hosted_zone               = "${var.live_hosted_zone}"
    jenkins_url                    = "${var.jenkins_url}"
    jenkins_admin_address          = "${var.jenkins_admin_address}"
    jenkins_agent_key_pair_prefix  = "${var.jenkins_agent_key_pair_prefix}"
    jenkins_agent_ami              = "${data.aws_ami.amazon_linux.id}"
    jenkins_agent_region           = "${var.aws_region}"
    jenkins_agent_subnet_id        = "${aws_subnet.subnet.id}"
    jenkins_agent_instance_profile = "${aws_iam_instance_profile.jenkins_agent_profile.arn}"
    jenkins_agent_security_groups  = "${aws_security_group.jenkins_agent_sg.id}"
    jenkins_agent_name             = "${var.stack_name}-jenkins-agent"
    jenkins_cloud_name             = "${var.jenkins_cloud_name}"
    aws_region                     = "${var.aws_region}"
  }
}

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
    volume = "${var.git_volume_device}"
  }
}

resource "aws_eip" "jenkins_eip" {
  vpc = true
}

resource "aws_eip_association" "jenkins_eip_assoc" {
  allocation_id = "${aws_eip.jenkins_eip.id}"
  instance_id   = "${aws_instance.jenkins.id}"
}

resource "aws_ebs_volume" "jenkins_volume" {
  availability_zone = "${aws_subnet.subnet.availability_zone}"
  size              = "${var.jenkins_volume_size}"
  type              = "gp2"

  tags {
    Name = "${var.stack_name}-jenkins"
  }
}

resource "aws_volume_attachment" "jenkins_volume_att" {
  device_name  = "/dev/${var.jenkins_volume_device}"
  instance_id  = "${aws_instance.jenkins.id}"
  volume_id    = "${aws_ebs_volume.jenkins_volume.id}"
  skip_destroy = true
}

resource "aws_iam_instance_profile" "jenkins_profile" {
  name  = "${var.stack_name}-jenkins-master"
  role  = "${aws_iam_role.jenkins_role.name}"
}

resource "aws_iam_role" "jenkins_role" {
  name               = "${var.stack_name}-jenkins-master"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "JenkinsAssumeRole",
      "Effect": "Allow",
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      }
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "jenkins_launch_agent_policy" {
  name   = "${var.stack_name}-jenkins-launch-agent"
  role   = "${aws_iam_role.jenkins_role.id}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "iam:PassRole",
      "Resource": "${aws_iam_role.jenkins_agent_role.arn}"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "jenkins_ec2_policy" {
  role       = "${aws_iam_role.jenkins_role.id}"
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}

resource "aws_iam_instance_profile" "jenkins_agent_profile" {
  name  = "${var.stack_name}-jenkins-agent"
  role  = "${aws_iam_role.jenkins_agent_role.name}"
}

resource "aws_iam_role" "jenkins_agent_role" {
  name               = "${var.stack_name}-jenkins-agent"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "JenkinsAgentAssumeRole",
      "Effect": "Allow",
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      }
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "jenkins_agent_test_deployment_policy" {
  name   = "${var.stack_name}-jenkins-agent-test-deployment"
  role   = "${aws_iam_role.jenkins_agent_role.id}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "sts:AssumeRole",
      "Resource": "${var.test_iam_role}"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "jenkins_agent_stage_deployment_policy" {
  name   = "${var.stack_name}-jenkins-agent-stage-deployment"
  role   = "${aws_iam_role.jenkins_agent_role.id}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "sts:AssumeRole",
      "Resource": "${var.stage_iam_role}"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "jenkins_agent_live_deployment_policy" {
  name   = "${var.stack_name}-jenkins-agent-live-deployment"
  role   = "${aws_iam_role.jenkins_agent_role.id}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "sts:AssumeRole",
      "Resource": "${var.live_iam_role}"
    }
  ]
}
EOF
}

resource "aws_security_group" "jenkins_sg" {
  name        = "${var.stack_name}-jenkins-sg"
  description = "Jenkins security group"
  vpc_id      = "${aws_vpc.vpc.id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "jenkins_agent_sg" {
  name        = "${var.stack_name}-jenkins-agent-sg"
  description = "Jenkins agent security group"
  vpc_id      = "${aws_vpc.vpc.id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "jenkins_agent_from_jenkins" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  security_group_id        = "${aws_security_group.jenkins_agent_sg.id}"
  source_security_group_id = "${aws_security_group.jenkins_sg.id}"
}

output "jenkins_public_ip" {
  value = "${aws_eip.jenkins_eip.public_ip}"
}
