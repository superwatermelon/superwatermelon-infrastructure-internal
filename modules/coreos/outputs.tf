output "ami" {
  value = "${data.aws_ami.coreos.id}"
}
