#
# Copyright (c) 2017 Superwatermelon Limited. All rights reserved.
#

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
  default = "10.128.16.4"
}

variable "git_instance_type" {
  description = "The AWS instance type to use for the instance"
  default = "t2.nano"
}

variable "git_key_pair" {
  description = "The name of the key pair to use"
  default = "git"
}

variable "git_snapshot_id" {
  # The snapshot to use for the Git volume, this can be the snapshot
  # created using the init-snapshot script or a snapshot created from
  # a backup of a pre-existing Git volume.
  description = "The ID of the Git volume snapshot"
  default = ""
}

variable "git_volume_device" {
  description = "The device name of the block storage volume"
  default = "xvdf"
}

variable "git_volume_size" {
  description = "The size of the volume in GB"
  default = 10
}

variable "git_format_volume" {
  description = "Should the Git volume be formatted (use for first launch)"
  default = false
}

resource "aws_instance" "git" {
  ami = "${data.aws_ami.coreos.id}"
  instance_type = "${var.git_instance_type}"
  private_ip = "${var.git_private_ip}"
  key_name = "${var.git_key_pair}"
  subnet_id = "${aws_subnet.subnet.id}"
  root_block_device {
    volume_type = "gp2"
  }
  tags {
    Name = "${var.stack_name}-git"
  }
  user_data = "${data.template_file.git_ignition.rendered}"
}

#
# Addition of users is mainly due to security paranoia, to
# prevent accidentally opening a vulnerability due to some
# misconfiguration.
#
# https://docs.docker.com/engine/security/security/#other-kernel-security-features
# > Docker containers are, by default, quite secure; especially
# > if you take care of running your processes inside the
# > containers as non-privileged users (i.e., non-root).
#
# The users on the host shadow the users in the containers
# to prevent accidental overlap of uids between the host
# and container which could expose accidental vulnerabilities.
#

data "template_file" "git_ignition" {
  template = <<EOF
{
  "ignition":{"version":"2.0.0"},
  "passwd":{
    "users":[
      {"name":"git","create":{"uid":1001}}
    ]
  },
  "systemd":{
    "units":[
      {"name":"docker.socket","enable":true},
      {"name":"containerd.service","enable":true},
      {"name":"docker.service","enable":true},
      {"name":"git.service","enable":true,"contents":$${git_service_unit}},
      {"name":"sshd.socket","enable":true,"contents":$${git_sshd_socket_unit}},
      {"name":"home-git.service","enable":true,"contents":$${git_home_service_unit}},
      {"name":"home-git.mount","enable":true,"contents":$${git_home_mount_unit}},
      {"name":"git-format.service","enable":$${git_format_service_enabled},"contents":$${git_format_service}}
    ]
  }
}
EOF
  vars = {
    git_service_unit = "${jsonencode(data.template_file.git_service_unit.rendered)}"
    git_sshd_socket_unit = "${jsonencode(data.template_file.git_sshd_socket_unit.rendered)}"
    git_home_service_unit = "${jsonencode(data.template_file.git_home_service_unit.rendered)}"
    git_home_mount_unit = "${jsonencode(data.template_file.git_home_mount_unit.rendered)}"
    git_format_service = "${jsonencode(data.template_file.git_format_service.rendered)}"
    git_format_service_enabled = "${var.git_format_volume == true}"
  }
}

data "template_file" "git_service_unit" {
  template = <<EOF
[Unit]
Requires=home-git.service docker.service
After=home-git.service docker.service
[Service]
Restart=always
ExecStart=/usr/bin/docker run \
  --publish 22:22 \
  --volume /home/git/ssh:/etc/ssh \
  --volume /home/git/repos:/var/git \
  --name jenkins superwatermelon/git
[Install]
WantedBy=multi-user.target
EOF
}

data "template_file" "git_sshd_socket_unit" {
  template = <<EOF
[Unit]
Conflicts=sshd.service
[Socket]
ListenStream=2222
FreeBind=true
Accept=yes
[Install]
WantedBy=sockets.target
EOF
}

data "template_file" "git_home_service_unit" {
  template = <<EOF
[Unit]
Requires=home-git.mount
After=home-git.mount
[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/bin/chown -R git:git /home/git
[Install]
WantedBy=multi-user.target
EOF
}

#
# Formatting in multi-user.target rather than local-fs.target
# as local-fs.target appears to be too soon and results in
# the format script occasionally reformatting an already
# formatted disk. The multi-user.target happens later. The
# following provides some useful information:
#
# https://www.freedesktop.org/software/systemd/man/bootup.html#System%20Manager%20Bootup
#
data "template_file" "git_home_mount_unit" {
  template = <<EOF
[Unit]
Requires=dev-$${volume}1.device
After=dev-$${volume}1.device git-format.service
[Mount]
What=/dev/$${volume}1
Where=/home/git
Type=ext4
[Install]
WantedBy=multi-user.target
EOF
  vars = {
    volume = "${var.git_volume_device}"
  }
}

data "template_file" "git_format_service" {
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

resource "aws_eip" "git_eip" {
  vpc = true
}

resource "aws_ebs_volume" "git_volume" {
  availability_zone = "${aws_subnet.subnet.availability_zone}"
  size = "${var.git_volume_size}"
  type = "gp2"
  tags {
    Name = "${var.stack_name}-git"
  }
}

resource "aws_eip_association" "git_eip_assoc" {
  allocation_id = "${aws_eip.git_eip.id}"
  instance_id = "${aws_instance.git.id}"
}

resource "aws_volume_attachment" "git_volume_att" {
  device_name = "/dev/${var.git_volume_device}"
  instance_id = "${aws_instance.git.id}"
  volume_id = "${aws_ebs_volume.git_volume.id}"
  skip_destroy = true
}

output "git_public_ip" {
  value = "${aws_eip.git_eip.public_ip}"
}
