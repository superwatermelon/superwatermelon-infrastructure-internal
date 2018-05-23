resource "aws_ebs_volume" "volume" {
  availability_zone = "${var.availability_zone}"
  size              = "${var.volume_size}"
  type              = "gp2"

  tags {
    Name = "jenkins"
  }
}

resource "aws_volume_attachment" "volume_att" {
  device_name  = "/dev/${var.volume}"
  instance_id  = "${aws_instance.instance.id}"
  volume_id    = "${aws_ebs_volume.volume.id}"
  skip_destroy = true
}
