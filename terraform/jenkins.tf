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
    Name = "jenkins"
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
