variable "stack_name" {
  description = "This is the name that is prefixed to the resources."
  default     = "tools"
}

variable "vpc_cidr_range" {
  description = "The CIDR range for the VPC."
  default     = "10.128.16.0/20"
}

variable "subnet_cidr_range" {
  description = "The CIDR range for the subnet."
  default     = "10.128.16.0/24"
}

variable "availability_zone" {
  description = "The availability zone into which to create the subnet."
  default     = "eu-west-1a"
}

variable "coreos_owner" {
  description = "The account ID for the owner of the CoreOS AMI."
  default     = "595879546273"
}

variable "aws_region" {
  description = "The region to use for deploying the stack."
  default     = "eu-west-1"
}

variable "internal_hosted_zone" {
  description = "The private hosted zone domain name for internal VPC."
}

provider "aws" {
  region = "${var.aws_region}"
}

data "aws_ami" "coreos" {
  most_recent = true
  owners      = ["${var.coreos_owner}"]

  filter {
    name = "name"
    values = ["CoreOS-stable-*"]
  }
  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_ami" "amazon_linux" {
  most_recent = true

  filter {
    name = "name"
    values = ["amzn-ami-hvm-*"]
  }
  filter {
    name = "owner-alias"
    values = ["amazon"]
  }
  filter {
    name = "block-device-mapping.volume-type"
    values = ["gp2"]
  }
  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_vpc" "vpc" {
  cidr_block           = "${var.vpc_cidr_range}"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags {
    Name = "${var.stack_name}-vpc"
  }
}

resource "aws_default_route_table" "default_rtb" {
  default_route_table_id = "${aws_vpc.vpc.default_route_table_id}"

  tags {
    Name = "${var.stack_name}-default-rtb"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = "${aws_vpc.vpc.id}"

  tags {
    Name = "${var.stack_name}-igw"
  }
}

resource "aws_route_table" "public_rtb" {
  vpc_id = "${aws_vpc.vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.igw.id}"
  }
  tags {
    Name = "${var.stack_name}-public-rtb"
  }
}

resource "aws_subnet" "subnet" {
  vpc_id                  = "${aws_vpc.vpc.id}"
  cidr_block              = "${var.subnet_cidr_range}"
  availability_zone       = "${var.availability_zone}"
  map_public_ip_on_launch = true

  tags {
    Name = "${var.stack_name}-subnet"
  }
}

resource "aws_route_table_association" "subnet_rtb" {
  subnet_id      = "${aws_subnet.subnet.id}"
  route_table_id = "${aws_route_table.public_rtb.id}"
}

resource "aws_security_group" "users_sg" {
  name        = "${var.stack_name}-users-sg"
  description = "User access security group"
  vpc_id      = "${aws_vpc.vpc.id}"
}

resource "aws_security_group_rule" "git_from_jenkins" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  security_group_id        = "${aws_security_group.git_sg.id}"
  source_security_group_id = "${aws_security_group.jenkins_sg.id}"
}

resource "aws_security_group_rule" "git_from_jenkins_agent" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  security_group_id        = "${aws_security_group.git_sg.id}"
  source_security_group_id = "${aws_security_group.jenkins_agent_sg.id}"
}

resource "aws_route53_zone" "internal_dns" {
  name    = "${var.internal_hosted_zone}"
  comment = "Internal DNS hosted zone"
  vpc_id  = "${aws_vpc.vpc.id}"

  tags {
    Name = "${var.stack_name}-zone"
  }
}

resource "aws_route53_record" "jenkins_internal_dns_record" {
  zone_id = "${aws_route53_zone.internal_dns.zone_id}"
  name    = "jenkins.${var.internal_hosted_zone}"
  type    = "A"
  ttl     = "300"
  records = ["${aws_instance.jenkins.private_ip}"]
}

resource "aws_route53_record" "git_internal_dns_record" {
  zone_id = "${aws_route53_zone.internal_dns.zone_id}"
  name    = "git.${var.internal_hosted_zone}"
  type    = "A"
  ttl     = "300"
  records = ["${aws_instance.git.private_ip}"]
}
