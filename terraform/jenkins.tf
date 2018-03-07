#
# A Jenkins server.
#
# It is backed by a general purpose EBS volume, 20 GB by default,
# configurable via the jenkins_volume_size variable.
#
# The availability_zone, subnet and coreos_ami are
# required variables. The availability_zone must match the
# availability zone of the subnet.
#

variable "jenkins_key_pair" {
  description = "The name of the key pair to use"
}

variable "jenkins_instance_type" {
  description = "The AWS instance type to use for the instance"
  default     = "t2.micro"
}

variable "jenkins_volume_device" {
  description = "The device name of the block storage volume"
  default     = "xvdf"
}

variable "jenkins_volume_size" {
  description = "The size of the volume in GB"
  default     = 10
}

resource "aws_instance" "jenkins" {
  ami                    = "${data.aws_ami.coreos.id}"
  instance_type          = "${var.jenkins_instance_type}"
  key_name               = "${var.jenkins_key_pair}"
  subnet_id              = "${aws_subnet.subnet.0.id}"
  iam_instance_profile   = "${aws_iam_instance_profile.jenkins_profile.id}"
  user_data              = "${data.template_file.jenkins_ignition.rendered}"
  vpc_security_group_ids = [
    "${aws_security_group.jenkins_sg.id}"
  ]

  root_block_device {
    volume_type = "gp2"
  }

  tags {
    Name = "jenkins"
  }
}

resource "aws_ebs_volume" "jenkins_volume" {
  availability_zone = "${aws_subnet.subnet.0.availability_zone}"
  size              = "${var.jenkins_volume_size}"
  type              = "gp2"

  tags {
    Name = "jenkins"
  }
}

resource "aws_volume_attachment" "jenkins_volume_att" {
  device_name  = "/dev/${var.jenkins_volume_device}"
  instance_id  = "${aws_instance.jenkins.id}"
  volume_id    = "${aws_ebs_volume.jenkins_volume.id}"
  skip_destroy = true
}

resource "aws_iam_instance_profile" "jenkins_profile" {
  name  = "jenkins-master"
  role  = "${aws_iam_role.jenkins_role.name}"
}

resource "aws_iam_role" "jenkins_role" {
  name               = "jenkins-master"
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

resource "aws_iam_role_policy_attachment" "jenkins_ec2_policy" {
  role       = "${aws_iam_role.jenkins_role.id}"
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}

resource "aws_iam_role_policy" "jenkins_internal_ecr_policy" {
  name   = "jenkins-master-internal-docker-registry"
  role   = "${aws_iam_role.jenkins_agent_role.id}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "sts:AssumeRole",
      "Resource": "${data.terraform_remote_state.seed.internal_ecr_role_arn}"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "jenkins_test_ecr_policy" {
  name   = "jenkins-master-test-docker-registry"
  role   = "${aws_iam_role.jenkins_agent_role.id}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "sts:AssumeRole",
      "Resource": "${data.terraform_remote_state.seed.test_ecr_role_arn}"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "jenkins_stage_ecr_policy" {
  name   = "jenkins-master-stage-docker-registry"
  role   = "${aws_iam_role.jenkins_agent_role.id}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "sts:AssumeRole",
      "Resource": "${data.terraform_remote_state.seed.stage_ecr_role_arn}"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "jenkins_live_ecr_policy" {
  name   = "jenkins-master-live-docker-registry"
  role   = "${aws_iam_role.jenkins_agent_role.id}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "sts:AssumeRole",
      "Resource": "${data.terraform_remote_state.seed.live_ecr_role_arn}"
    }
  ]
}
EOF
}
