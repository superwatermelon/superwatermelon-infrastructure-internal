output "profile_arn" {
  value = "${aws_iam_instance_profile.profile.arn}"
}

output "role_arn" {
  value = "${aws_iam_role.role.arn}"
}
