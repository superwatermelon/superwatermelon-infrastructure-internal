#
# A Git server that hosts Git repositories over SSH.
#
# It is backed by a general purpose EBS volume, by default,
# 10GB in size. This can be configured using the git_volume_size
# variable.
#
# The availability_zone, subnet and coreos_ami are
# required variables. The availability_zone must match the
# availability zone of the subnet.
#

variable "git_private_ip" {
  description = "The private IP to use for the instance"

  # The default value here falls within the subnet range
  # specified as subnet_cidr_range in main.tf.
  default     = "10.128.16.4"
}

variable "git_instance_type" {
  description = "The AWS instance type to use for the instance"
  default     = "t2.nano"
}

variable "git_key_pair" {
  description = "The name of the key pair to use"
  default = "git"
}

variable "git_volume_device" {
  description = "The device name of the block storage volume"
  default     = "xvdf"
}

variable "git_volume_size" {
  description = "The size of the volume in GB"
  default     = 10
}

resource "aws_instance" "git" {
  ami                    = "${data.aws_ami.coreos.id}"
  instance_type          = "${var.git_instance_type}"
  private_ip             = "${var.git_private_ip}"
  key_name               = "${var.git_key_pair}"
  subnet_id              = "${aws_subnet.subnet.0.id}"
  user_data              = "${data.template_file.git_ignition.rendered}"
  vpc_security_group_ids = [
    "${aws_security_group.git_sg.id}",
    "${aws_security_group.users_sg.id}"
  ]

  root_block_device {
    volume_type = "gp2"
  }

  tags {
    Name = "git"
  }
}

resource "aws_eip" "git_eip" {
  vpc = true
}

resource "aws_ebs_volume" "git_volume" {
  availability_zone = "${aws_subnet.subnet.0.availability_zone}"
  size              = "${var.git_volume_size}"
  type              = "gp2"

  tags {
    Name = "git"
  }
}

resource "aws_eip_association" "git_eip_assoc" {
  allocation_id = "${aws_eip.git_eip.id}"
  instance_id   = "${aws_instance.git.id}"
}

resource "aws_volume_attachment" "git_volume_att" {
  device_name  = "/dev/${var.git_volume_device}"
  instance_id  = "${aws_instance.git.id}"
  volume_id    = "${aws_ebs_volume.git_volume.id}"
  skip_destroy = true
}

output "git_public_ip" {
  value = "${aws_eip.git_eip.public_ip}"
}
