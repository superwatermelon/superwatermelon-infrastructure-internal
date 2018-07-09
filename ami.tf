variable "coreos_owner" {
  description = "The account ID for the owner of the CoreOS AMI."
  default     = "595879546273"
}

data "aws_ami" "coreos" {
  most_recent = true
  owners      = ["${var.coreos_owner}"]

  filter {
    name   = "name"
    values = ["CoreOS-stable-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_ami" "amazon_linux" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn-ami-hvm-*"]
  }
  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }
  filter {
    name   = "block-device-mapping.volume-type"
    values = ["gp2"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
