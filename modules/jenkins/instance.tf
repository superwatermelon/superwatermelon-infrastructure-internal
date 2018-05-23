resource "aws_instance" "instance" {
  ami                    = "${module.coreos.ami}"
  instance_type          = "${var.instance_type}"
  key_name               = "${var.key_name}"
  subnet_id              = "${var.subnet_id}"
  iam_instance_profile   = "${aws_iam_instance_profile.profile.id}"
  user_data              = "${data.ignition_config.ignition.rendered}"
  vpc_security_group_ids = [
    "${var.vpc_security_group_ids}"
  ]

  root_block_device {
    volume_type = "gp2"
  }

  tags {
    Name = "jenkins"
  }
}
