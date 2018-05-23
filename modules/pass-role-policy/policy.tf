resource "aws_iam_role_policy" "policy" {
  name   = "${var.name}"
  role   = "${var.source_role_id}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "iam:PassRole",
      "Resource": "${var.pass_role_arn}"
    }
  ]
}
EOF
}
