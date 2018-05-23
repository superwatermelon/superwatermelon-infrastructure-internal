resource "aws_iam_instance_profile" "profile" {
  name  = "jenkins-master"
  role  = "${aws_iam_role.role.name}"
}
