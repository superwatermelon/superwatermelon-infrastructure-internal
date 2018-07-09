resource "aws_iam_instance_profile" "profile" {
  name  = "${var.name}"
  role  = "${aws_iam_role.role.name}"
}
